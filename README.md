# AulaKnob

A native macOS menu bar app that customizes the AULA F75 rotary knob. It runs
in the background, reads the knob's media key events, and remaps them. No Windows
software is needed.

Built in Swift with AppKit, CoreAudio, CGEvent, and IOKit. The app has no Dock
icon and lives in the menu bar.

## Requirements

- macOS 13 or later
- An AULA F75

## Install

1. Download the latest `AulaKnob-vX.Y.Z-macos-arm64.zip` from
   [Releases](https://github.com/ayush-gzip/AulaKnob/releases) and unzip it.
2. Move `AulaKnob.app` to your Applications folder, or run `./install.sh` from a
   source checkout.
3. The app is not notarized. On first launch, right click it and choose Open,
   then confirm. If macOS still blocks it, run:
   ```bash
   xattr -dr com.apple.quarantine /Applications/AulaKnob.app
   ```
4. Grant Accessibility. macOS needs this permission to read the knob's media
   keys. Open System Settings > Privacy & Security > Accessibility and turn on
   AulaKnob. If the knob does nothing, quit and reopen the app once so it reads
   the new permission.

## Modes

Rotate the knob to act on the current mode. Switch modes from the menu bar, or
hold the knob to cycle through them.

| Mode | Rotate | Click |
| --- | --- | --- |
| Volume and Media | Volume up and down | Play or pause |
| Screen Brightness | Brightness up and down | Toggle 50% and 100% |
| Smooth Scroll and Zoom | Scroll up and down | Toggle zoom mode (Cmd +/-) |
| Desktop Spaces | Switch spaces (Ctrl + Left/Right) | Mission Control |
| Browser and Editor Tabs | Cycle tabs (Cmd + Shift + [ and ]) | Close tab (Cmd + W) |
| Video and Media Scrubbing | Jump 5 seconds back and forward | Play or pause (Space) |
| App Switcher | Cycle apps (Cmd + Tab) | Select the active app |
| Passthrough | Standard macOS media key handling | Standard |

## Knob clicks

- Single click: the mode action, or a fixed action you set in the menu.
- Double click: next track by default.
- Triple click: previous track by default.
- Hold: cycle to the next mode.

Single, double, triple, and hold actions are all configurable from the menu bar.

## Modifier shortcuts

Hold a modifier and rotate for an instant action without switching modes:

- Shift: adjust display brightness
- Option: smooth page scroll or zoom
- Command: switch browser and editor tabs
- Control: switch desktop spaces

## Menu bar controls

- Active mode and pause toggle
- Mode selection
- Menu bar icon style
- Single click and double click actions
- Sensitivity (0.5x, 1.0x, 1.5x, 2.0x)
- Rotation and click interception toggles
- Accessibility status

## AULA F75 hardware mode

The F75 knob has two hardware modes. AulaKnob only works in the media key mode.

- Volume mode (ring LED blue): sends media keys to the Mac. Use this mode.
- Lighting mode (ring LED green): controls the keyboard backlight.

To switch hardware modes, hold the knob for about 3 to 5 seconds until the ring
LED flashes.

## Build from source

```bash
swift build -c release      # build the binary
./build_app.sh              # build and codesign the .app bundle
```

## Project structure

```
keeb/
├── AulaKnob.app/             compiled app bundle
├── Package.swift             Swift Package Manager manifest
├── build_app.sh              build and codesign script
├── install.sh                install to /Applications
└── Sources/AulaKnob/
    ├── main.swift            entry point
    ├── AppDelegate.swift     lifecycle and activation policy
    ├── Models/
    │   ├── KnobMode.swift        mode enum and metadata
    │   └── KnobSettings.swift    UserDefaults persistence
    ├── Core/
    │   ├── KnobEventTap.swift        CGEventTap media key interception
    │   ├── KnobActionManager.swift   action dispatch and key synthesis
    │   ├── AudioController.swift      CoreAudio volume and media
    │   ├── BrightnessController.swift display brightness
    │   ├── AccessibilityHelper.swift  permissions
    │   └── LaunchAtLoginHelper.swift  SMAppService registration
    └── UI/
        ├── KnobHUDController.swift   floating HUD overlay
        └── KnobStatusBar.swift       menu bar item and menu
```
