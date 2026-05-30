// mt-orient: durable, per-device Magic Trackpad orientation manager.
//
// The original mt-orientation flips ALL transport==4 (Bluetooth) devices to the
// same orientation. That cannot express "trackpad A normal, trackpad B flipped",
// and it breaks the moment a device moves between USB and Bluetooth.
//
// mt-orient keys orientation to each device's **ProductID** (hardware model id),
// which is stable across USB and Bluetooth. It correlates each live multitouch
// device (via MultitouchSupport) to its IOKit AppleMultitouchDevice record by
// matching MTDeviceGetDeviceID == IOKit "Multitouch ID", then reads "ProductID".
//
// Why ProductID and not serial/transport/GUID:
//   - Transport (USB vs Bluetooth) changes when you plug/unplug a cable.
//   - The reported SerialNumber is the BT MAC over Bluetooth but the real
//     hardware serial over USB -- so it is NOT stable across transports.
//   - The MultitouchSupport GUID is MAC-derived over BT, location-derived over USB.
//   - ProductID is a fixed hardware model id: 0x0324=804 (newer Magic Trackpad),
//     0x0265=613 (Magic Trackpad 2). It does not change with the cable.
//
// Devices whose ProductID is not listed in the config are left UNTOUCHED.
//
// config: ~/.hammerspoon/trackpad-orientation/orient.conf
//   product 804 normal
//   product 613 upside-down
//
// modes:
//   mt-orient list     list devices (index, transport, productID, resolved desired)
//   mt-orient apply    apply policy once, print actions
//   mt-orient watch    daemon: apply on device-set change, self-heal every 60s
//   mt-orient reset    force all external trackpads back to normal (for uninstall)

#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>
#include <dlfcn.h>
#include <unistd.h>
#include <time.h>

typedef void *MTDeviceRef;
typedef CFMutableArrayRef (*ListFn)(void);
typedef int  (*TransFn)(MTDeviceRef, int *);
typedef int  (*BuiltInFn)(MTDeviceRef);
typedef int  (*DevIDFn)(MTDeviceRef, uint64_t *);
typedef int  (*SetOrientFn)(MTDeviceRef, int);

enum { ORIENT_NORMAL = 0, ORIENT_UPSIDE_DOWN = 2, ORIENT_SKIP = -2 };

static ListFn      MTDeviceCreateList;
static TransFn     MTDeviceGetTransportMethod;
static BuiltInFn   MTDeviceIsBuiltIn;
static DevIDFn     MTDeviceGetDeviceID;
static SetOrientFn MTDeviceSetSurfaceOrientation;

// ---- config -------------------------------------------------------------
#define MAX_RULES 16
static int ruleProduct[MAX_RULES];
static int ruleOrient[MAX_RULES];
static int ruleCount = 0;

static void loadConfig(void) {
    ruleCount = 0;
    const char *home = getenv("HOME");
    if (!home) return;
    char path[1024];
    snprintf(path, sizeof(path), "%s/.hammerspoon/trackpad-orientation/orient.conf", home);
    FILE *f = fopen(path, "r");
    if (!f) return;
    char line[256];
    while (fgets(line, sizeof(line), f)) {
        if (line[0] == '#') continue;
        char key[32], orientStr[32]; int product;
        if (sscanf(line, "%31s %d %31s", key, &product, orientStr) != 3) continue;
        if (strcmp(key, "product") != 0) continue;
        if (ruleCount >= MAX_RULES) break;
        ruleProduct[ruleCount] = product;
        ruleOrient[ruleCount]  = (strcmp(orientStr, "normal") == 0) ? ORIENT_NORMAL : ORIENT_UPSIDE_DOWN;
        ruleCount++;
    }
    fclose(f);
}

static int desiredForProduct(int product) {
    for (int i = 0; i < ruleCount; i++)
        if (ruleProduct[i] == product) return ruleOrient[i];
    return ORIENT_SKIP;
}

// ---- IOKit: MultitouchID -> ProductID ----------------------------------
static int productForMultitouchID(uint64_t mtid) {
    io_iterator_t it;
    if (IOServiceGetMatchingServices(kIOMainPortDefault,
            IOServiceMatching("AppleMultitouchDevice"), &it) != KERN_SUCCESS)
        return -1;
    io_object_t svc; int found = -1;
    while ((svc = IOIteratorNext(it))) {
        CFNumberRef midRef = IORegistryEntryCreateCFProperty(svc, CFSTR("Multitouch ID"), kCFAllocatorDefault, 0);
        CFNumberRef pidRef = IORegistryEntryCreateCFProperty(svc, CFSTR("ProductID"),     kCFAllocatorDefault, 0);
        if (midRef && pidRef) {
            uint64_t mid = 0; int pid = 0;
            CFNumberGetValue(midRef, kCFNumberSInt64Type, &mid);
            CFNumberGetValue(pidRef, kCFNumberIntType, &pid);
            if (mid == mtid) found = pid;
        }
        if (midRef) CFRelease(midRef);
        if (pidRef) CFRelease(pidRef);
        IOObjectRelease(svc);
        if (found >= 0) break;
    }
    IOObjectRelease(it);
    return found;
}

// ---- framework ----------------------------------------------------------
static int loadFramework(void) {
    void *fw = dlopen("/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport", RTLD_LAZY);
    if (!fw) { fprintf(stderr, "mt-orient: cannot open MultitouchSupport: %s\n", dlerror()); return 0; }
    MTDeviceCreateList            = (ListFn)dlsym(fw, "MTDeviceCreateList");
    MTDeviceGetTransportMethod    = (TransFn)dlsym(fw, "MTDeviceGetTransportMethod");
    MTDeviceIsBuiltIn             = (BuiltInFn)dlsym(fw, "MTDeviceIsBuiltIn");
    MTDeviceGetDeviceID           = (DevIDFn)dlsym(fw, "MTDeviceGetDeviceID");
    MTDeviceSetSurfaceOrientation = (SetOrientFn)dlsym(fw, "MTDeviceSetSurfaceOrientation");
    if (!MTDeviceCreateList || !MTDeviceGetTransportMethod || !MTDeviceIsBuiltIn ||
        !MTDeviceGetDeviceID || !MTDeviceSetSurfaceOrientation) {
        fprintf(stderr, "mt-orient: missing MultitouchSupport symbols\n"); return 0;
    }
    return 1;
}

static int applyOnce(int verbose) {
    CFMutableArrayRef devs = MTDeviceCreateList();
    if (!devs) { if (verbose) fprintf(stderr, "mt-orient: no devices\n"); return 0; }
    CFIndex n = CFArrayGetCount(devs);
    int changed = 0;
    for (CFIndex i = 0; i < n; i++) {
        MTDeviceRef d = (MTDeviceRef)CFArrayGetValueAtIndex(devs, i);
        if (MTDeviceIsBuiltIn(d)) continue;
        uint64_t mtid = 0; MTDeviceGetDeviceID(d, &mtid);
        int product = productForMultitouchID(mtid);
        int want = desiredForProduct(product);
        if (want == ORIENT_SKIP) {
            if (verbose) printf("device %ld: product=%d -> SKIP (not configured)\n", (long)i, product);
            continue;
        }
        int r = MTDeviceSetSurfaceOrientation(d, want);
        changed++;
        if (verbose) {
            int transport = -1; MTDeviceGetTransportMethod(d, &transport);
            printf("device %ld: product=%d transport=%d -> setOrientation=%d result=%d\n",
                   (long)i, product, transport, want, r);
        }
    }
    CFRelease(devs);
    return changed;
}

// Force every external (non-builtin) multitouch device to normal. Used by uninstall.
static int resetAll(int verbose) {
    CFMutableArrayRef devs = MTDeviceCreateList();
    if (!devs) return 0;
    CFIndex n = CFArrayGetCount(devs);
    int changed = 0;
    for (CFIndex i = 0; i < n; i++) {
        MTDeviceRef d = (MTDeviceRef)CFArrayGetValueAtIndex(devs, i);
        if (MTDeviceIsBuiltIn(d)) continue;
        int r = MTDeviceSetSurfaceOrientation(d, ORIENT_NORMAL);
        changed++;
        if (verbose) printf("device %ld: -> setOrientation=0 result=%d\n", (long)i, r);
    }
    CFRelease(devs);
    return changed;
}

static void listDevices(void) {
    CFMutableArrayRef devs = MTDeviceCreateList();
    if (!devs) { fprintf(stderr, "mt-orient: no devices\n"); return; }
    CFIndex n = CFArrayGetCount(devs);
    for (CFIndex i = 0; i < n; i++) {
        MTDeviceRef d = (MTDeviceRef)CFArrayGetValueAtIndex(devs, i);
        int transport = -1; MTDeviceGetTransportMethod(d, &transport);
        int builtIn = MTDeviceIsBuiltIn(d);
        uint64_t mtid = 0; MTDeviceGetDeviceID(d, &mtid);
        int product = builtIn ? -1 : productForMultitouchID(mtid);
        int want = builtIn ? -1 : desiredForProduct(product);
        printf("device %ld: transport=%d builtIn=%d product=%d desired=%d\n",
               (long)i, transport, builtIn, product, want);
    }
    CFRelease(devs);
}

// signature of connected external devices (sorted multitouch ids) for change detect
static int deviceSignature(char *sig, size_t siglen) {
    sig[0] = '\0';
    CFMutableArrayRef devs = MTDeviceCreateList();
    if (!devs) return 0;
    CFIndex n = CFArrayGetCount(devs);
    uint64_t ids[32]; int gc = 0;
    for (CFIndex i = 0; i < n && gc < 32; i++) {
        MTDeviceRef d = (MTDeviceRef)CFArrayGetValueAtIndex(devs, i);
        if (MTDeviceIsBuiltIn(d)) continue;
        uint64_t id = 0; MTDeviceGetDeviceID(d, &id); ids[gc++] = id;
    }
    CFRelease(devs);
    for (int i = 1; i < gc; i++) { uint64_t t = ids[i]; int j = i-1; while (j>=0 && ids[j]>t){ids[j+1]=ids[j];j--;} ids[j+1]=t; }
    for (int i = 0; i < gc; i++) {
        char buf[24]; snprintf(buf, sizeof(buf), "%llu;", ids[i]);
        strncat(sig, buf, siglen - strlen(sig) - 1);
    }
    return gc;
}

int main(int argc, const char *argv[]) {
    const char *mode = (argc >= 2) ? argv[1] : "apply";
    if (!loadFramework()) return 1;
    loadConfig();

    if (strcmp(mode, "list") == 0)  { listDevices(); return 0; }
    if (strcmp(mode, "apply") == 0) { return applyOnce(1) > 0 ? 0 : 2; }
    if (strcmp(mode, "reset") == 0) { resetAll(1); return 0; }

    if (strcmp(mode, "watch") == 0) {
        char lastSig[800] = ""; char sig[800];
        time_t lastApply = 0;
        for (;;) {
            loadConfig(); // live-reload edits
            int count = deviceSignature(sig, sizeof(sig));
            time_t now = time(NULL);
            int setChanged = strcmp(sig, lastSig) != 0;
            int selfHeal   = (now - lastApply) >= 60;
            if (count > 0 && (setChanged || selfHeal)) {
                applyOnce(0);
                lastApply = now;
            }
            strncpy(lastSig, sig, sizeof(lastSig) - 1);
            sleep(2);
        }
    }

    fprintf(stderr, "usage: %s list|apply|watch\n", argv[0]);
    return 64;
}
