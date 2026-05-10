# MagicMirror

MagicMirror flips an Apple Magic Trackpad for upside-down use on macOS.

It does not warp the cursor, intercept pointer events, or require
BetterTouchTool. Instead, it calls Apple's private MultitouchSupport framework
to set the trackpad surface orientation directly.

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
