import Foundation
import Cocoa

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var axCheckTimer: Timer?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        KnobStatusBar.shared.setup()
        let started = KnobEventTap.shared.start()
        
        if started {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                KnobHUDController.shared.show(
                    title: "AulaKnob Ready",
                    detail: KnobSettings.shared.activeMode.displayName,
                    iconName: "dial.low.fill",
                    mode: KnobSettings.shared.activeMode
                )
            }
        } else {
            // Check periodically if permission gets granted in System Settings
            axCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] timer in
                if AccessibilityHelper.isAccessibilityGranted() {
                    if KnobEventTap.shared.start() {
                        timer.invalidate()
                        self?.axCheckTimer = nil
                        KnobStatusBar.shared.updateStatusItem()
                        KnobHUDController.shared.show(
                            title: "Permission Granted",
                            detail: "AulaKnob is now active!",
                            iconName: "checkmark.circle.fill",
                            mode: .volume
                        )
                    }
                }
            }
        }
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        KnobEventTap.shared.stop()
    }
}
