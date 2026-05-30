# MagicMirror

MagicMirror flips an Apple Magic Trackpad for upside-down use on macOS.

It does not warp the cursor, intercept pointer events, or require
BetterTouchTool. Instead, it calls Apple's private MultitouchSupport framework
to set the trackpad surface orientation directly.

With **two trackpads** it can keep one normal and the other flipped, durably:
a small `mt-orient` daemon assigns orientation per device by **ProductID** (the
hardware model id, which is stable whether a trackpad is on USB or Bluetooth)
and re-applies it across reconnects, wake, and login. See
[Multiple trackpads](#multiple-trackpads-durable-per-device).

## Why

Apple's Magic Trackpad is physically comfortable upside down in some desk setups,
but macOS does not expose a modern setting for mirroring pointer and scroll
directions. Event-tap approaches can make the direction correct, but they often
cause ghost cursors, jitter, stuck clicks, or jumpy motion.

MagicMirror uses the same class of driver-level orientation path that dedicated
tools use, but packages it as a tiny local helper.

## Install

```sh
git clone https://github.com/smkwray/magicmirror.git
cd magicmirror
./install.sh
```

The installer compiles `src/mt-orientation.m`, installs runtime scripts under:

```text
~/.hammerspoon/trackpad-orientation/
```

and installs a login LaunchAgent:

```text
~/Library/LaunchAgents/com.smkwray.magicmirror.plist
```

The LaunchAgent reapplies the saved orientation at login.

## Usage

Apply upside-down orientation:

```sh
~/.hammerspoon/trackpad-orientation/apply-upside-down.sh
```

Apply normal orientation:

```sh
~/.hammerspoon/trackpad-orientation/apply-normal.sh
```

Toggle saved state:

```sh
~/.hammerspoon/trackpad-orientation/toggle.sh
```

List detected multitouch devices:

```sh
~/.hammerspoon/trackpad-orientation/mt-orientation list
```

Expected output on an external Bluetooth Magic Trackpad:

```text
device 0: transport=4 builtIn=0
```

Expected output when applying upside-down:

```text
device 0: transport=4 builtIn=0 setOrientation=2 result=0
```

Normal orientation is `0`; upside-down orientation is `2`.

## Multiple trackpads (durable, per-device)

The original `mt-orientation` helper flips **all** external Bluetooth trackpads
to the same orientation. That cannot express "trackpad A normal, trackpad B
flipped", and it breaks when a device moves between USB and Bluetooth (the
device index and transport both change).

`mt-orient` solves this by keying orientation to each device's **ProductID**.
It correlates every live multitouch device to its IOKit `AppleMultitouchDevice`
record (matching `MTDeviceGetDeviceID` to the IOKit `Multitouch ID`) and reads
`ProductID` — a fixed hardware model id that does **not** change with the cable.
Transport, device index, GUID, and the reported serial are all
connection-dependent and therefore unsuitable as keys.

Configure the mapping in `~/.hammerspoon/trackpad-orientation/orient.conf`:

```text
# <productID> <normal|upside-down>; unlisted devices are left untouched
product 804 normal         # 0x0324  newer Magic Trackpad
product 613 upside-down    # 0x0265  Magic Trackpad 2

# which model toggle.sh / the Hyper+' shortcut flips
toggle-target 613
```

Find your ProductIDs with `mt-orient list`. Commands:

```sh
mt-orient list     # show devices, ProductIDs, and resolved orientation
mt-orient apply    # apply the config once
mt-orient watch    # daemon: re-apply on reconnect/wake, self-heal every 60s
mt-orient reset    # force all external trackpads back to normal
```

The installer runs `mt-orient watch` from the login LaunchAgent with
`KeepAlive`, so the per-device orientation survives reconnect, sleep/wake, and
reboot. The `toggle.sh` / `apply-*.sh` scripts edit `orient.conf` and re-apply,
so the manual shortcut and the daemon cooperate instead of fighting.

## Optional Integrations

Karabiner-Elements:

- Import or copy `examples/karabiner-rule.json`.
- The example maps Hyper+quote to the installed `toggle.sh`.

Hammerspoon:

- Copy `examples/hammerspoon-menubar.lua` into `~/.hammerspoon/init.lua`.
- It adds a small `TP UD` / `TP OK` menu bar item.

## Uninstall

```sh
./uninstall.sh
```

This resets the trackpad to normal, unloads the LaunchAgent, and removes the
installed runtime folder.

## How It Works

`src/mt-orientation.m` dynamically loads:

```text
/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport
```

and calls:

```text
MTDeviceCreateList
MTDeviceGetTransportMethod
MTDeviceIsBuiltIn
MTDeviceSetSurfaceOrientation
```

The helper targets external Bluetooth multitouch devices:

```text
transport=4 builtIn=0
```

## Caveat

This uses private Apple API. It is free and local, but Apple could rename or
remove these symbols in a future macOS release.

## Sources

- [Ask Different: palm rejection on Apple Trackpad 2](https://apple.stackexchange.com/questions/312971/palm-rejection-on-apple-trackpad-2)
- [Ask Different: reverse Magic Trackpad](https://apple.stackexchange.com/questions/121499/reverse-magic-trackpad-turn-180)
- [Cult of Mac: use Magic Trackpad upside down](https://www.cultofmac.com/how-to/how-to-use-your-mac-magic-trackpad-upside-down)

## License

MIT
