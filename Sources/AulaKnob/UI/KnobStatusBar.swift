import Foundation
import Cocoa

public final class KnobStatusBar: NSObject {
    public static let shared = KnobStatusBar()
    
    private var statusItem: NSStatusItem?
    private let settings = KnobSettings.shared
    
    override private init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: KnobSettings.modeChangedNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: KnobSettings.settingsChangedNotification,
            object: nil
        )
    }
    
    public func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusItem()
    }
    
    @objc private func settingsChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.updateStatusItem()
        }
    }
    
    public func updateStatusItem() {
        guard let button = statusItem?.button else { return }
        
        let currentMode = settings.activeMode
        let style = settings.menuBarIconStyle
        
        let iconImage = KnobIconGenerator.createKnobIcon(mode: currentMode, style: style)
        button.image = iconImage
        button.title = ""
        button.toolTip = settings.isPaused ? "AulaKnob (Paused)" : "Aula F75 Knob: \(currentMode.displayName)"
        
        rebuildMenu()
    }
    
    private func rebuildMenu() {
        let menu = NSMenu()
        
        // Header
        let titleItem = NSMenuItem(title: "Aula F75 Knob Customizer", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        if let font = NSFont.boldSystemFont(ofSize: 13) as NSFont? {
            titleItem.attributedTitle = NSAttributedString(
                string: "Aula F75 Knob Customizer",
                attributes: [.font: font]
            )
        }
        menu.addItem(titleItem)
        
        let statusStr = settings.isPaused ? "Status: ⏸️ Paused (Keys Untouched)" : "Active Mode: \(settings.activeMode.displayName)"
        let subTitle = NSMenuItem(title: statusStr, action: nil, keyEquivalent: "")
        subTitle.isEnabled = false
        menu.addItem(subTitle)
        
        menu.addItem(NSMenuItem.separator())
        
        // Pause / Resume Toggle
        let pauseItem = NSMenuItem(
            title: settings.isPaused ? "▶️ Resume Knob Customization" : "⏸️ Pause Knob Customization",
            action: #selector(togglePause),
            keyEquivalent: "p"
        )
        pauseItem.target = self
        menu.addItem(pauseItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Mode Selection Section
        let modeSection = NSMenuItem(title: "Knob Modes", action: nil, keyEquivalent: "")
        modeSection.isEnabled = false
        menu.addItem(modeSection)
        
        for mode in KnobMode.allCases {
            let item = NSMenuItem(
                title: "\(mode.menuIcon)  \(mode.displayName)",
                action: #selector(modeSelected(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = mode
            item.state = (mode == settings.activeMode && !settings.isPaused) ? .on : .off
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Menu Bar Icon Style Submenu
        let iconStyleMenu = NSMenu()
        for style in MenuBarIconStyle.allCases {
            let item = NSMenuItem(
                title: style.displayName,
                action: #selector(iconStyleSelected(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = style
            item.state = (style == settings.menuBarIconStyle) ? .on : .off
            iconStyleMenu.addItem(item)
        }
        let iconStyleSubmenuItem = NSMenuItem(title: "Menu Bar Icon Style", action: nil, keyEquivalent: "")
        iconStyleSubmenuItem.submenu = iconStyleMenu
        menu.addItem(iconStyleSubmenuItem)
        
        // Click Action Submenu
        let clickMenu = NSMenu()
        for action in ClickAction.allCases {
            let item = NSMenuItem(
                title: action.displayName,
                action: #selector(clickActionSelected(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = action
            item.state = (action == settings.singleClickAction) ? .on : .off
            clickMenu.addItem(item)
        }
        let clickSubmenuItem = NSMenuItem(title: "Knob Click Action", action: nil, keyEquivalent: "")
        clickSubmenuItem.submenu = clickMenu
        menu.addItem(clickSubmenuItem)
        
        // Double Click Action Submenu
        let doubleClickMenu = NSMenu()
        for action in ClickAction.allCases {
            let item = NSMenuItem(
                title: action.displayName,
                action: #selector(doubleClickActionSelected(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = action
            item.state = (action == settings.doubleClickAction) ? .on : .off
            doubleClickMenu.addItem(item)
        }
        let doubleClickSubmenuItem = NSMenuItem(title: "Knob Double-Click Action", action: nil, keyEquivalent: "")
        doubleClickSubmenuItem.submenu = doubleClickMenu
        menu.addItem(doubleClickSubmenuItem)
        
        // Sensitivity Submenu
        let sensMenu = NSMenu()
        let sensOptions: [(String, Double)] = [
            ("0.5x (Slow / Fine)", 0.5),
            ("1.0x (Standard)", 1.0),
            ("1.5x (Fast)", 1.5),
            ("2.0x (Ultra Fast)", 2.0)
        ]
        for (title, val) in sensOptions {
            let item = NSMenuItem(
                title: title,
                action: #selector(sensitivitySelected(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = val
            item.state = (abs(settings.sensitivity - val) < 0.01) ? .on : .off
            sensMenu.addItem(item)
        }
        let sensSubmenuItem = NSMenuItem(title: "Knob Sensitivity", action: nil, keyEquivalent: "")
        sensSubmenuItem.submenu = sensMenu
        menu.addItem(sensSubmenuItem)
        
        // Function Keys & Interception Settings Submenu
        let fnMenu = NSMenu()
        
        let rotItem = NSMenuItem(
            title: "Intercept Knob Rotation (Volume Up/Down)",
            action: #selector(toggleInterceptRotation),
            keyEquivalent: ""
        )
        rotItem.target = self
        rotItem.state = settings.interceptRotation ? .on : .off
        fnMenu.addItem(rotItem)
        
        let muteItem = NSMenuItem(
            title: "Intercept Knob Click (Mute Key / F10)",
            action: #selector(toggleInterceptMute),
            keyEquivalent: ""
        )
        muteItem.target = self
        muteItem.state = settings.interceptMuteKey ? .on : .off
        fnMenu.addItem(muteItem)
        
        let modOnlyItem = NSMenuItem(
            title: "Protect F11/F12: Only Trigger Custom Modes with Modifiers",
            action: #selector(toggleRequireModifierForSpecial),
            keyEquivalent: ""
        )
        modOnlyItem.target = self
        modOnlyItem.state = settings.requireModifierForSpecialModes ? .on : .off
        fnMenu.addItem(modOnlyItem)
        
        fnMenu.addItem(NSMenuItem.separator())
        
        let openKbPref = NSMenuItem(
            title: "Open macOS Function Keys (F1-F12) Settings...",
            action: #selector(openKeyboardSettings),
            keyEquivalent: ""
        )
        openKbPref.target = self
        fnMenu.addItem(openKbPref)
        
        let fnSubmenuItem = NSMenuItem(title: "Function Keys & Interception", action: nil, keyEquivalent: "")
        fnSubmenuItem.submenu = fnMenu
        menu.addItem(fnSubmenuItem)
        
        // Preferences Submenu
        let optionsMenu = NSMenu()
        
        let hudItem = NSMenuItem(
            title: "Show On-Screen HUD Overlay",
            action: #selector(toggleHUD),
            keyEquivalent: ""
        )
        hudItem.target = self
        hudItem.state = settings.showHUD ? .on : .off
        optionsMenu.addItem(hudItem)
        
        let invertItem = NSMenuItem(
            title: "Invert Rotation Direction",
            action: #selector(toggleInvert),
            keyEquivalent: ""
        )
        invertItem.target = self
        invertItem.state = settings.invertRotation ? .on : .off
        optionsMenu.addItem(invertItem)
        
        let modItem = NSMenuItem(
            title: "Enable Modifier Key Shortcuts (Shift/Opt/Cmd/Ctrl)",
            action: #selector(toggleModifierOverrides),
            keyEquivalent: ""
        )
        modItem.target = self
        modItem.state = settings.modifierOverridesEnabled ? .on : .off
        optionsMenu.addItem(modItem)
        
        let loginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = LaunchAtLoginHelper.isEnabled ? .on : .off
        optionsMenu.addItem(loginItem)
        
        let optionsSubmenuItem = NSMenuItem(title: "Preferences", action: nil, keyEquivalent: "")
        optionsSubmenuItem.submenu = optionsMenu
        menu.addItem(optionsSubmenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Accessibility Permission Status
        let isTrusted = AccessibilityHelper.isAccessibilityGranted()
        let axItem = NSMenuItem(
            title: isTrusted ? "✓ Accessibility: Enabled" : "⚠️ Grant Accessibility Permission...",
            action: #selector(openAccessibility),
            keyEquivalent: ""
        )
        axItem.target = self
        menu.addItem(axItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(
            title: "Quit AulaKnob",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func togglePause() {
        settings.isPaused.toggle()
        KnobHUDController.shared.show(
            title: settings.isPaused ? "AulaKnob Paused" : "AulaKnob Resumed",
            detail: settings.isPaused ? "Function keys restored" : settings.activeMode.displayName,
            iconName: settings.isPaused ? "pause.circle.fill" : "play.circle.fill",
            mode: settings.activeMode
        )
        rebuildMenu()
    }
    
    @objc private func toggleInterceptRotation() {
        settings.interceptRotation.toggle()
        rebuildMenu()
    }
    
    @objc private func toggleInterceptMute() {
        settings.interceptMuteKey.toggle()
        rebuildMenu()
    }
    
    @objc private func toggleRequireModifierForSpecial() {
        settings.requireModifierForSpecialModes.toggle()
        rebuildMenu()
    }
    
    @objc private func openKeyboardSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func modeSelected(_ sender: NSMenuItem) {
        if let mode = sender.representedObject as? KnobMode {
            if settings.isPaused {
                settings.isPaused = false
            }
            settings.activeMode = mode
            KnobHUDController.shared.show(
                title: "Mode Switched",
                detail: mode.displayName,
                iconName: mode.sfSymbol,
                mode: mode
            )
        }
    }
    
    @objc private func iconStyleSelected(_ sender: NSMenuItem) {
        if let style = sender.representedObject as? MenuBarIconStyle {
            settings.menuBarIconStyle = style
        }
    }
    
    @objc private func clickActionSelected(_ sender: NSMenuItem) {
        if let action = sender.representedObject as? ClickAction {
            settings.singleClickAction = action
        }
    }
    
    @objc private func doubleClickActionSelected(_ sender: NSMenuItem) {
        if let action = sender.representedObject as? ClickAction {
            settings.doubleClickAction = action
        }
    }
    
    @objc private func sensitivitySelected(_ sender: NSMenuItem) {
        if let val = sender.representedObject as? Double {
            settings.sensitivity = val
        }
    }
    
    @objc private func toggleHUD() {
        settings.showHUD.toggle()
    }
    
    @objc private func toggleInvert() {
        settings.invertRotation.toggle()
    }
    
    @objc private func toggleModifierOverrides() {
        settings.modifierOverridesEnabled.toggle()
    }
    
    @objc private func toggleLaunchAtLogin() {
        let current = LaunchAtLoginHelper.isEnabled
        LaunchAtLoginHelper.setEnabled(!current)
        rebuildMenu()
    }
    
    @objc private func openAccessibility() {
        if !AccessibilityHelper.isAccessibilityGranted() {
            AccessibilityHelper.requestAccessibilityPrompt()
            AccessibilityHelper.openAccessibilitySettings()
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
