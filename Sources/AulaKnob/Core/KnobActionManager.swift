import Foundation
import Cocoa
import Carbon.HIToolbox

public final class KnobActionManager {
    public static let shared = KnobActionManager()
    
    private let settings = KnobSettings.shared
    private let audio = AudioController.shared
    private let brightness = BrightnessController.shared
    
    // Zoom submode state when in .scroll mode
    private var isZoomMode: Bool = false
    
    private init() {}
    
    public func handleRotate(direction: Int, modifiers: NSEvent.ModifierFlags) {
        // direction: +1 for Clockwise (Right), -1 for Counter-Clockwise (Left)
        let effectiveDirection = settings.invertRotation ? -direction : direction
        let mode = determineEffectiveMode(modifiers: modifiers)
        let sensitivity = Float(settings.sensitivity)
        
        switch mode {
        case .volume:
            let delta = Float(effectiveDirection) * 0.04 * sensitivity
            let newVol = audio.adjustVolume(delta: delta)
            let isMuted = audio.isMuted()
            let icon = isMuted ? "speaker.slash.fill" : (newVol > 0.5 ? "speaker.wave.3.fill" : (newVol > 0 ? "speaker.wave.1.fill" : "speaker.slash.fill"))
            KnobHUDController.shared.show(
                title: "Volume",
                detail: "\(Int(round(newVol * 100)))%",
                progress: newVol,
                iconName: icon,
                mode: .volume
            )
            
        case .brightness:
            let delta = Float(effectiveDirection) * 0.05 * sensitivity
            let newBrightness = brightness.adjustBrightness(delta: delta)
            KnobHUDController.shared.show(
                title: "Brightness",
                detail: "\(Int(round(newBrightness * 100)))%",
                progress: newBrightness,
                iconName: newBrightness > 0.5 ? "sun.max.fill" : "sun.min.fill",
                mode: .brightness
            )
            
        case .scroll:
            if isZoomMode {
                if effectiveDirection > 0 {
                    // Zoom In: Cmd + +
                    simulateKey(keyCode: CGKeyCode(kVK_ANSI_Equal), flags: .maskCommand)
                    KnobHUDController.shared.show(title: "Zoom", detail: "Zoom In (+)", iconName: "plus.magnifyingglass", mode: .scroll)
                } else {
                    // Zoom Out: Cmd + -
                    simulateKey(keyCode: CGKeyCode(kVK_ANSI_Minus), flags: .maskCommand)
                    KnobHUDController.shared.show(title: "Zoom", detail: "Zoom Out (-)", iconName: "minus.magnifyingglass", mode: .scroll)
                }
            } else {
                // Scroll: Smooth pixel scroll
                let scrollAmount = Int32(Float(effectiveDirection * -24) * sensitivity)
                simulateScroll(deltaY: scrollAmount)
                // Do not show full HUD on every scroll tick to avoid blocking view, but can show subtle indicator if requested
            }
            
        case .spaces:
            if effectiveDirection > 0 {
                // Next Space: Ctrl + Right Arrow
                simulateKey(keyCode: CGKeyCode(kVK_RightArrow), flags: .maskControl)
                KnobHUDController.shared.show(title: "Desktop Spaces", detail: "Next Space", iconName: "arrow.right.to.line.compact", mode: .spaces)
            } else {
                // Prev Space: Ctrl + Left Arrow
                simulateKey(keyCode: CGKeyCode(kVK_LeftArrow), flags: .maskControl)
                KnobHUDController.shared.show(title: "Desktop Spaces", detail: "Previous Space", iconName: "arrow.left.to.line.compact", mode: .spaces)
            }
            
        case .tabs:
            if effectiveDirection > 0 {
                // Next Tab: Cmd + Shift + ] (or Cmd + Option + Right)
                simulateKey(keyCode: CGKeyCode(kVK_ANSI_RightBracket), flags: [.maskCommand, .maskShift])
                KnobHUDController.shared.show(title: "Tabs", detail: "Next Tab", iconName: "chevron.right.2", mode: .tabs)
            } else {
                // Previous Tab: Cmd + Shift + [ (or Cmd + Option + Left)
                simulateKey(keyCode: CGKeyCode(kVK_ANSI_LeftBracket), flags: [.maskCommand, .maskShift])
                KnobHUDController.shared.show(title: "Tabs", detail: "Previous Tab", iconName: "chevron.left.2", mode: .tabs)
            }
            
        case .scrub:
            if effectiveDirection > 0 {
                // Scrub forward 5s: Right Arrow
                simulateKey(keyCode: CGKeyCode(kVK_RightArrow), flags: [])
                KnobHUDController.shared.show(title: "Scrubbing", detail: "Forward +5s ⏩", iconName: "goforward.5", mode: .scrub)
            } else {
                // Scrub backward 5s: Left Arrow
                simulateKey(keyCode: CGKeyCode(kVK_LeftArrow), flags: [])
                KnobHUDController.shared.show(title: "Scrubbing", detail: "Rewind -5s ⏪", iconName: "gobackward.5", mode: .scrub)
            }
            
        case .appSwitch:
            if effectiveDirection > 0 {
                // Next App: Cmd + Tab
                simulateKey(keyCode: CGKeyCode(kVK_Tab), flags: .maskCommand)
                KnobHUDController.shared.show(title: "App Switcher", detail: "Next App", iconName: "square.grid.2x2.fill", mode: .appSwitch)
            } else {
                // Prev App: Cmd + Shift + Tab
                simulateKey(keyCode: CGKeyCode(kVK_Tab), flags: [.maskCommand, .maskShift])
                KnobHUDController.shared.show(title: "App Switcher", detail: "Previous App", iconName: "square.grid.2x2", mode: .appSwitch)
            }
            
        case .passthrough:
            // Native pass-through
            break
        }
    }
    
    public func handleClick(action: ClickAction, sourceMode: KnobMode? = nil) {
        let currentMode = sourceMode ?? settings.activeMode
        
        switch action {
        case .modeDefault:
            executeDefaultClickForMode(currentMode)
            
        case .cycleMode:
            let next = settings.activeMode.nextMode
            settings.activeMode = next
            KnobHUDController.shared.show(
                title: "Mode Switched",
                detail: next.displayName,
                iconName: next.sfSymbol,
                mode: next
            )
            
        case .cycleModeBackwards:
            let prev = settings.activeMode.previousMode
            settings.activeMode = prev
            KnobHUDController.shared.show(
                title: "Mode Switched",
                detail: prev.displayName,
                iconName: prev.sfSymbol,
                mode: prev
            )
            
        case .playPause:
            audio.playPause()
            KnobHUDController.shared.show(title: "Media", detail: "Play / Pause", iconName: "playpause.fill", mode: .volume)
            
        case .muteUnmute:
            let muted = audio.toggleMute()
            let vol = audio.getVolume()
            KnobHUDController.shared.show(
                title: "Volume",
                detail: muted ? "Muted" : "\(Int(round(vol * 100)))%",
                progress: muted ? 0.0 : vol,
                iconName: muted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                mode: .volume
            )
            
        case .nextTrack:
            audio.nextTrack()
            KnobHUDController.shared.show(title: "Media", detail: "Next Track ⏭", iconName: "forward.end.fill", mode: .volume)
            
        case .prevTrack:
            audio.previousTrack()
            KnobHUDController.shared.show(title: "Media", detail: "Previous Track ⏮", iconName: "backward.end.fill", mode: .volume)
            
        case .missionControl:
            simulateKey(keyCode: CGKeyCode(kVK_UpArrow), flags: .maskControl)
            KnobHUDController.shared.show(title: "Mission Control", detail: "All Windows", iconName: "macwindow.on.rectangle", mode: .spaces)
            
        case .showDesktop:
            simulateKey(keyCode: CGKeyCode(kVK_F11), flags: [])
            KnobHUDController.shared.show(title: "Show Desktop", detail: "Desktop", iconName: "menubar.rectangle", mode: .spaces)
            
        case .toggleZoom:
            isZoomMode.toggle()
            let modeName = isZoomMode ? "Zoom Mode (Magnify)" : "Scroll Mode (Pixel Scroll)"
            let icon = isZoomMode ? "plus.magnifyingglass" : "arrow.up.and.down"
            KnobHUDController.shared.show(title: "Scroll / Zoom", detail: modeName, iconName: icon, mode: .scroll)
            
        case .closeTab:
            simulateKey(keyCode: CGKeyCode(kVK_ANSI_W), flags: .maskCommand)
            KnobHUDController.shared.show(title: "Tabs", detail: "Closed Tab (Cmd+W)", iconName: "xmark.circle.fill", mode: .tabs)
            
        case .newTab:
            simulateKey(keyCode: CGKeyCode(kVK_ANSI_T), flags: .maskCommand)
            KnobHUDController.shared.show(title: "Tabs", detail: "New Tab (Cmd+T)", iconName: "plus.circle.fill", mode: .tabs)
            
        case .spacebar:
            simulateKey(keyCode: CGKeyCode(kVK_Space), flags: [])
            KnobHUDController.shared.show(title: "Playback", detail: "Spacebar", iconName: "playpause", mode: .scrub)
            
        case .none:
            break
        }
    }
    
    private func executeDefaultClickForMode(_ mode: KnobMode) {
        switch mode {
        case .volume:
            handleClick(action: .playPause, sourceMode: mode)
        case .brightness:
            let current = brightness.getBrightness()
            let target: Float = current < 0.5 ? 0.75 : 0.35
            brightness.setBrightness(target)
            KnobHUDController.shared.show(
                title: "Brightness",
                detail: "\(Int(round(target * 100)))%",
                progress: target,
                iconName: "sun.max.fill",
                mode: .brightness
            )
        case .scroll:
            handleClick(action: .toggleZoom, sourceMode: mode)
        case .spaces:
            handleClick(action: .missionControl, sourceMode: mode)
        case .tabs:
            handleClick(action: .newTab, sourceMode: mode)
        case .scrub:
            handleClick(action: .spacebar, sourceMode: mode)
        case .appSwitch:
            simulateKey(keyCode: CGKeyCode(kVK_Return), flags: [])
        case .passthrough:
            break
        }
    }
    
    public func handleSingleClick() {
        handleClick(action: settings.singleClickAction)
    }
    
    public func handleDoubleClick() {
        handleClick(action: settings.doubleClickAction)
    }
    
    public func handleTripleClick() {
        handleClick(action: settings.tripleClickAction)
    }
    
    public func handleLongPress() {
        handleClick(action: settings.longPressAction)
    }
    
    private func determineEffectiveMode(modifiers: NSEvent.ModifierFlags) -> KnobMode {
        if settings.modifierOverridesEnabled {
            if modifiers.contains(.shift) {
                return .brightness
            } else if modifiers.contains(.option) {
                return .scroll
            } else if modifiers.contains(.command) {
                return .tabs
            } else if modifiers.contains(.control) {
                return .spaces
            }
        }
        
        if settings.requireModifierForSpecialModes {
            // Bare turns / F11 / F12 only adjust volume unless a modifier key is held
            return .volume
        }
        
        return settings.activeMode
    }
    
    private func simulateKey(keyCode: CGKeyCode, flags: CGEventFlags) {
        let source = CGEventSource(stateID: .combinedSessionState)
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) {
            keyDown.flags = flags
            keyDown.post(tap: .cghidEventTap)
        }
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
            keyUp.flags = flags
            keyUp.post(tap: .cghidEventTap)
        }
    }
    
    private func simulateScroll(deltaY: Int32, deltaX: Int32 = 0) {
        if let scroll = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: deltaY, wheel2: deltaX, wheel3: 0) {
            scroll.post(tap: .cghidEventTap)
        }
    }
}
