#import <Foundation/Foundation.h>
#include <dlfcn.h>

typedef void *MTDeviceRef;

typedef CFMutableArrayRef (*MTDeviceCreateListFn)(void);
typedef int (*MTDeviceGetTransportMethodFn)(MTDeviceRef, int *);
typedef int (*MTDeviceIsBuiltInFn)(MTDeviceRef);
typedef int (*MTDeviceSetSurfaceOrientationFn)(MTDeviceRef, int);

enum {
    OrientationNormal = 0,
    OrientationUpsideDown = 2,
    TransportBluetooth = 4
};

static void usage(const char *name) {
    fprintf(stderr, "usage: %s normal|upside-down|list\n", name);
}

int main(int argc, const char *argv[]) {
    if (argc != 2) {
        usage(argv[0]);
        return 64;
    }

    NSString *command = [NSString stringWithUTF8String:argv[1]];
    int desiredOrientation = OrientationNormal;
    BOOL listOnly = NO;

    if ([command isEqualToString:@"upside-down"] || [command isEqualToString:@"inverted"]) {
        desiredOrientation = OrientationUpsideDown;
    } else if ([command isEqualToString:@"normal"]) {
        desiredOrientation = OrientationNormal;
    } else if ([command isEqualToString:@"list"]) {
        listOnly = YES;
    } else {
        usage(argv[0]);
        return 64;
    }

    void *framework = dlopen(
        "/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport",
        RTLD_LAZY
    );
    if (!framework) {
        fprintf(stderr, "failed to open MultitouchSupport.framework: %s\n", dlerror());
        return 1;
    }

    MTDeviceCreateListFn MTDeviceCreateList = (MTDeviceCreateListFn)dlsym(framework, "MTDeviceCreateList");
    MTDeviceGetTransportMethodFn MTDeviceGetTransportMethod = (MTDeviceGetTransportMethodFn)dlsym(framework, "MTDeviceGetTransportMethod");
    MTDeviceIsBuiltInFn MTDeviceIsBuiltIn = (MTDeviceIsBuiltInFn)dlsym(framework, "MTDeviceIsBuiltIn");
    MTDeviceSetSurfaceOrientationFn MTDeviceSetSurfaceOrientation = (MTDeviceSetSurfaceOrientationFn)dlsym(framework, "MTDeviceSetSurfaceOrientation");

    if (!MTDeviceCreateList || !MTDeviceGetTransportMethod || !MTDeviceIsBuiltIn || !MTDeviceSetSurfaceOrientation) {
        fprintf(stderr, "failed to load required MultitouchSupport symbols\n");
        return 1;
    }

    CFMutableArrayRef devices = MTDeviceCreateList();
    if (!devices) {
        fprintf(stderr, "no multitouch devices returned\n");
        return 1;
    }

    CFIndex count = CFArrayGetCount(devices);
    int changed = 0;

    for (CFIndex i = 0; i < count; i++) {
        MTDeviceRef device = (MTDeviceRef)CFArrayGetValueAtIndex(devices, i);
        int transport = -1;
        MTDeviceGetTransportMethod(device, &transport);
        int builtIn = MTDeviceIsBuiltIn(device);

        printf("device %ld: transport=%d builtIn=%d", (long)i, transport, builtIn);

        if (!listOnly && transport == TransportBluetooth && !builtIn) {
            int result = MTDeviceSetSurfaceOrientation(device, desiredOrientation);
            printf(" setOrientation=%d result=%d", desiredOrientation, result);
            changed++;
        }

        printf("\n");
    }

    CFRelease(devices);

    if (!listOnly && changed == 0) {
        fprintf(stderr, "no external Bluetooth multitouch device found\n");
        return 2;
    }

    return 0;
}
