# MagicMirror

MagicMirror flips an external Apple Magic Trackpad for upside-down use on macOS. Instead of intercepting pointer events, which tends to cause jitter, ghost cursors and stuck clicks, it calls Apple's private MultitouchSupport framework to set the trackpad's surface orientation directly. A login LaunchAgent re-applies your settings when a trackpad reconnects, after wake and after a restart.

Orientation is set per trackpad model, by its hardware ProductID, which stays the same over USB and Bluetooth. Two trackpads with different ProductIDs can have different orientations; two of the same model share one setting. Because MagicMirror uses a private Apple API, a future macOS update could break it.

## Install

Installing needs the Xcode command-line tools (`xcode-select --install`).

```sh
git clone https://github.com/smkwray/magicmirror.git
cd magicmirror
./install.sh
```

The installer compiles the `mt-orient` helper, copies it and the scripts to `~/.hammerspoon/trackpad-orientation/`, and loads the LaunchAgent `~/Library/LaunchAgents/com.smkwray.magicmirror.plist`. A first install changes no trackpad until you configure one, and reinstalling keeps your configuration. Hammerspoon is not required; the folder name only matters for the optional integration below.

## Configure

List the connected trackpads to find their ProductIDs:

```sh
~/.hammerspoon/trackpad-orientation/mt-orient list
```

```text
device 0: transport=1 builtIn=0 product=804 desired=0
```

Then set an orientation for each model in `~/.hammerspoon/trackpad-orientation/orient.conf`. ProductIDs you do not list are left alone.

```text
# product <ProductID> <normal|upside-down>
product 804 normal
product 613 upside-down

# Trackpad that toggle.sh and apply-*.sh change when given no ProductID
toggle-target 613
```

The LaunchAgent applies changes to this file within a minute; `mt-orient apply` applies them at once.

## Usage

`toggle.sh`, `apply-upside-down.sh` and `apply-normal.sh` save the change to `orient.conf` and apply it at once. Each takes an optional ProductID and otherwise uses `toggle-target`.

```sh
cd ~/.hammerspoon/trackpad-orientation
./toggle.sh                # switch between normal and upside-down
./apply-upside-down.sh
./apply-normal.sh
./apply-current.sh         # re-apply orient.conf once
```

`mt-orient` in the same folder has four commands:

```sh
./mt-orient list     # show trackpads, ProductIDs and configured orientation
./mt-orient apply    # apply orient.conf once
./mt-orient watch    # keep applying it (what the LaunchAgent runs)
./mt-orient reset    # set every external trackpad back to normal
```

Only `0` (normal) and `2` (upside-down) orientations are supported. The LaunchAgent logs to `/tmp/magicmirror.out.log` and `/tmp/magicmirror.err.log`.

## Optional Hammerspoon menu

Copy `examples/hammerspoon-menubar.lua` into `~/.hammerspoon/init.lua` to get a menu bar item that shows `TP UD` or `TP OK` and offers Upside-down, Normal, Toggle and Reapply Current.

## Uninstall

```sh
./uninstall.sh
```

This stops the LaunchAgent, resets connected external trackpads to normal, and removes the installed folder and LaunchAgent.

## How it works

`mt-orient` loads `/System/Library/PrivateFrameworks/MultitouchSupport.framework` at run time and calls `MTDeviceCreateList`, `MTDeviceGetTransportMethod`, `MTDeviceIsBuiltIn`, `MTDeviceGetDeviceID` and `MTDeviceSetSurfaceOrientation`. It skips built-in trackpads and reads each external trackpad's ProductID from its IOKit `AppleMultitouchDevice` record. In watch mode it checks the connected devices every two seconds, applies the configuration when they change, and re-applies it every 60 seconds.

## Sources

- [Ask Different: palm rejection on Apple Trackpad 2](https://apple.stackexchange.com/questions/312971/palm-rejection-on-apple-trackpad-2)
- [Ask Different: reverse Magic Trackpad](https://apple.stackexchange.com/questions/121499/reverse-magic-trackpad-turn-180)
- [Cult of Mac: use Magic Trackpad upside down](https://www.cultofmac.com/how-to/how-to-use-your-mac-magic-trackpad-upside-down)

## License

MIT. See [LICENSE](LICENSE).
