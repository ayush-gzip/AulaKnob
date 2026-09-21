import Foundation
import Cocoa
import ApplicationServices

public struct AccessibilityHelper {
    public static func isAccessibilityGranted() -> Bool {
        return AXIsProcessTrusted()
    }
    
    @discardableResult
    public static func requestAccessibilityPrompt() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    public static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
