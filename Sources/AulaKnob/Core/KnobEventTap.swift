import Foundation
import Cocoa

public final class KnobEventTap {
    public static let shared = KnobEventTap()
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isRunning = false
    
    // Click / Multi-click / Long-press handling
    private var clickCount = 0
    private var clickTimer: Timer?
    private var longPressTimer: Timer?
    private var isLongPressActive = false
    
    private init() {}
    
    public func start() -> Bool {
        guard !isRunning else { return true }
        
        // Check accessibility
        guard AccessibilityHelper.isAccessibilityGranted() else {
            print("Accessibility permission is not granted. Requesting...")
            AccessibilityHelper.requestAccessibilityPrompt()
            return false
        }
        
        let eventMask = (1 << 14) // NX_SYSDEFINED
        
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else {
                    return Unmanaged.passRetained(event)
                }
                let tapInstance = Unmanaged<KnobEventTap>.fromOpaque(refcon).takeUnretainedValue()
                return tapInstance.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: selfPointer
        ) else {
            print("Failed to create CGEventTap.")
            return false
        }
        
        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
        self.isRunning = true
        print("AulaKnob EventTap started successfully.")
        return true
    }
    
    public func stop() {
        guard isRunning, let tap = eventTap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        self.eventTap = nil
        self.runLoopSource = nil
        self.isRunning = false
    }
    
    public var isTapActive: Bool {
        return isRunning && eventTap != nil
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }
        
        guard type.rawValue == 14 else { // NX_SYSDEFINED
            return Unmanaged.passRetained(event)
        }
        
        // If paused or in passthrough mode, pass through all events cleanly
        let settings = KnobSettings.shared
        if settings.isPaused || settings.activeMode == .passthrough {
            return Unmanaged.passRetained(event)
        }
        
        guard let nsEvent = NSEvent(cgEvent: event), nsEvent.subtype.rawValue == 8 else {
            return Unmanaged.passRetained(event)
        }
        
        let data1 = nsEvent.data1
        let keyCode = (data1 & 0xFFFF0000) >> 16
        let keyFlags = (data1 & 0x0000FFFF)
        let isKeyDown = ((keyFlags & 0xFF00) >> 8) == 0xA
        let isKeyUp = ((keyFlags & 0xFF00) >> 8) == 0xB
        
        let modifierFlags = nsEvent.modifierFlags

        switch keyCode {
        case 0: // NX_KEYTYPE_SOUND_UP (Rotate Clockwise)
            guard settings.interceptRotation else {
                return Unmanaged.passRetained(event)
            }
            if isKeyDown {
                DispatchQueue.main.async {
                    KnobActionManager.shared.handleRotate(direction: 1, modifiers: modifierFlags)
                }
            }
            return nil // Swallow event for knob customization
            
        case 1: // NX_KEYTYPE_SOUND_DOWN (Rotate Counter-Clockwise)
            guard settings.interceptRotation else {
                return Unmanaged.passRetained(event)
            }
            if isKeyDown {
                DispatchQueue.main.async {
                    KnobActionManager.shared.handleRotate(direction: -1, modifiers: modifierFlags)
                }
            }
            return nil // Swallow event for knob customization
            
        case 7: // NX_KEYTYPE_MUTE (Knob Click / Press)
            guard settings.interceptMuteKey else {
                return Unmanaged.passRetained(event)
            }
            if isKeyDown {
                handleKnobButtonDown()
            } else if isKeyUp {
                handleKnobButtonUp()
            }
            return nil // Swallow event for knob click
            
        // Never intercept Play/Pause (16), Brightness (2, 3), Next (17), Prev (18)
        // so standard keyboard function keys F1-F9 work completely untouched!
        default:
            return Unmanaged.passRetained(event)
        }
    }
    
    private func handleKnobButtonDown() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isLongPressActive = false
            self.longPressTimer?.invalidate()
            
            // Start long press timer (450ms)
            self.longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                self.isLongPressActive = true
                self.clickTimer?.invalidate()
                self.clickCount = 0
                KnobActionManager.shared.handleLongPress()
            }
        }
    }
    
    private func handleKnobButtonUp() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.longPressTimer?.invalidate()
            
            if self.isLongPressActive {
                self.isLongPressActive = false
                return
            }
            
            self.clickCount += 1
            self.clickTimer?.invalidate()
            
            // Wait for potential double/triple clicks (240ms)
            self.clickTimer = Timer.scheduledTimer(withTimeInterval: 0.24, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                let count = self.clickCount
                self.clickCount = 0
                
                if count == 1 {
                    KnobActionManager.shared.handleSingleClick()
                } else if count == 2 {
                    KnobActionManager.shared.handleDoubleClick()
                } else if count >= 3 {
                    KnobActionManager.shared.handleTripleClick()
                }
            }
        }
    }
}
