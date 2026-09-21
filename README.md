# 🎛️ AulaKnob for macOS (Aula F75 & Mechanical Keyboard Knob Controller)

A native, ultra-lightweight macOS menu bar application and background daemon built in Swift that unlocks full customization for the **AULA F75** rotary knob on Mac (with zero Windows software needed).

---

## ✨ Features

- **⚡ Native & Featherlight:** Built with pure Swift & Apple frameworks (CoreAudio, AppKit, CGEvent, IOKit).
- **🎛️ Multi-Mode Knob Controller:**
  - 🔊 **Volume & Media:** Rotate for volume (fine steps), single click for Play/Pause, double-click for Next Track, triple-click for Previous Track.
  - ☀️ **Screen Brightness:** Smooth display brightness adjustment.
  - 📜 **Smooth Scroll & Zoom:** Pixel-smooth vertical scrolling, single click to toggle Zoom mode (`Cmd +` / `Cmd -`).
  - 🪟 **Desktop Spaces & Mission Control:** Switch spaces (`Ctrl + Left/Right`), click for Mission Control (`Ctrl + Up`), double-click for Desktop.
  - 📑 **Browser & Code Editor Tabs:** Cycle tabs (`Cmd + Shift + [/]` or `Cmd + Option + Left/Right`), click to open new tab (`Cmd + T`) or close tab (`Cmd + W`).
  - ⏩ **Video & Media Scrubbing:** 5-second jump forward/back in YouTube/media players, click to toggle Play/Pause (Space).
  - 🔀 **App Switcher:** Rotate to cycle open apps (`Cmd + Tab`), click to select.
  - ⌨️ **Passthrough Mode:** Standard macOS media key handling.
- **🔄 Instant Modifier Shortcuts (Zero Mode Switching Needed):**
  - Hold **`Shift`** + Rotate Knob ➔ **Adjust Display Brightness**
  - Hold **`Option`** + Rotate Knob ➔ **Smooth Page Scroll / Zoom**
  - Hold **`Command`** + Rotate Knob ➔ **Switch Browser/Editor Tabs**
  - Hold **`Control`** + Rotate Knob ➔ **Switch Desktop Spaces**
- **🔘 Smart Knob Clicks:**
  - Single Click: Context action (Play/Pause, Toggle Zoom, Mission Control, New Tab, or Cycle Mode)
  - Double Click: Next Track / Customizable
  - Triple Click: Previous Track / Customizable
  - Long Press (Hold): Fast cycle through modes
- **🖥️ Translucent On-Screen HUD Overlay:** Floating glass pill displaying the active mode, level bar, and SF Symbol.
- **🚀 Launch at Login Support:** Start automatically on Mac boot.
- **⚙️ Menu Bar Status Item:** Quick mode switcher, sensitivity adjustment (0.5x, 1.0x, 1.5x, 2.0x), invert direction toggle, and settings.

---

## 🚀 Quick Start

### 1. Launch AulaKnob
From this directory:
```bash
open AulaKnob.app
```
Or install to your Applications folder:
```bash
./install.sh
```

### 2. Grant Accessibility Permissions (One-time macOS requirement)
Because macOS requires Accessibility permission to intercept keyboard rotary knob media keys:
1. When you first launch the app, macOS will prompt you to open **System Settings**.
2. Go to **System Settings > Privacy & Security > Accessibility**.
3. Enable **AulaKnob** (or click the status bar icon and choose **Grant Accessibility Permission**).

### 3. Ensure Aula F75 Hardware Mode
The AULA F75 knob has two built-in hardware modes:
- **Volume Mode (Default - Light around knob is BLUE):** Sends media key events to Mac. **AulaKnob works in this mode!**
- **Lighting Mode (Light around knob is GREEN):** Controls RGB backlight on keyboard hardware.
- *To toggle hardware modes, press and hold the knob down for ~3-5 seconds until the ring LED flashes.*

---

## 🛠️ Building from Source

To rebuild after making code changes:
```bash
./build_app.sh
```
Or build via Swift Package Manager:
```bash
swift build -c release
```

---

## 📂 Project Structure

```
keeb/
├── AulaKnob.app/             # Compiled macOS Application Bundle
├── Package.swift             # Swift Package Manager manifest
├── build_app.sh              # Production build & codesign script
├── install.sh                # Install to /Applications script
└── Sources/
    └── AulaKnob/
        ├── main.swift        # Application entrypoint
        ├── AppDelegate.swift # Lifecycle & activation policy
        ├── Models/
        │   ├── KnobMode.swift     # Mode enum & metadata
        │   └── KnobSettings.swift # UserDefaults persistence
        ├── Core/
        │   ├── KnobEventTap.swift      # CGEventTap media key interception
        │   ├── KnobActionManager.swift # Action dispatch & key synthesis
        │   ├── AudioController.swift   # CoreAudio volume & media playback
        │   ├── BrightnessController.swift # Display brightness control
        │   ├── AccessibilityHelper.swift  # Permissions manager
        │   └── LaunchAtLoginHelper.swift  # SMAppService registration
        └── UI/
            ├── KnobHUDController.swift # Translucent floating HUD
            └── KnobStatusBar.swift     # Menu bar status item & menu
```
