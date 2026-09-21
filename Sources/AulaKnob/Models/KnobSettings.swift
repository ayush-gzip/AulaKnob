import Foundation

public final class KnobSettings: ObservableObject {
    public static let shared = KnobSettings()
    
    private let defaults = UserDefaults.standard
    
    public static let modeChangedNotification = Notification.Name("AulaKnobModeChanged")
    public static let settingsChangedNotification = Notification.Name("AulaKnobSettingsChanged")
    
    private enum Keys {
        static let activeMode = "aula_active_mode"
        static let singleClickAction = "aula_single_click_action"
        static let doubleClickAction = "aula_double_click_action"
        static let tripleClickAction = "aula_triple_click_action"
        static let longPressAction = "aula_long_press_action"
        static let sensitivity = "aula_sensitivity"
        static let invertRotation = "aula_invert_rotation"
        static let showHUD = "aula_show_hud"
        static let hudPosition = "aula_hud_position"
        static let modifierOverrides = "aula_modifier_overrides"
        static let launchAtLogin = "aula_launch_at_login"
        static let menuBarIconStyle = "aula_menubar_icon_style"
        static let isPaused = "aula_is_paused"
        static let interceptMuteKey = "aula_intercept_mute_key"
        static let interceptRotation = "aula_intercept_rotation"
        static let requireModifierForSpecialModes = "aula_require_modifier_for_special"
    }
    
    private init() {
        // Register default values
        defaults.register(defaults: [
            Keys.activeMode: KnobMode.volume.rawValue,
            Keys.singleClickAction: ClickAction.modeDefault.rawValue,
            Keys.doubleClickAction: ClickAction.nextTrack.rawValue,
            Keys.tripleClickAction: ClickAction.prevTrack.rawValue,
            Keys.longPressAction: ClickAction.cycleMode.rawValue,
            Keys.sensitivity: 1.0,
            Keys.invertRotation: false,
            Keys.showHUD: true,
            Keys.hudPosition: HUDPosition.bottomCenter.rawValue,
            Keys.modifierOverrides: true,
            Keys.launchAtLogin: false,
            Keys.menuBarIconStyle: MenuBarIconStyle.rotaryKnob.rawValue,
            Keys.isPaused: false,
            Keys.interceptMuteKey: true,
            Keys.interceptRotation: true,
            Keys.requireModifierForSpecialModes: false
        ])
    }
    
    public var isPaused: Bool {
        get { defaults.bool(forKey: Keys.isPaused) }
        set {
            defaults.set(newValue, forKey: Keys.isPaused)
            notifyChanged()
        }
    }
    
    public var interceptMuteKey: Bool {
        get { defaults.bool(forKey: Keys.interceptMuteKey) }
        set {
            defaults.set(newValue, forKey: Keys.interceptMuteKey)
            notifyChanged()
        }
    }
    
    public var interceptRotation: Bool {
        get { defaults.bool(forKey: Keys.interceptRotation) }
        set {
            defaults.set(newValue, forKey: Keys.interceptRotation)
            notifyChanged()
        }
    }
    
    public var requireModifierForSpecialModes: Bool {
        get { defaults.bool(forKey: Keys.requireModifierForSpecialModes) }
        set {
            defaults.set(newValue, forKey: Keys.requireModifierForSpecialModes)
            notifyChanged()
        }
    }
    
    public var activeMode: KnobMode {
        get {
            guard let raw = defaults.string(forKey: Keys.activeMode),
                  let mode = KnobMode(rawValue: raw) else {
                return .volume
            }
            return mode
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.activeMode)
            NotificationCenter.default.post(name: KnobSettings.modeChangedNotification, object: newValue)
        }
    }
    
    public var singleClickAction: ClickAction {
        get {
            guard let raw = defaults.string(forKey: Keys.singleClickAction),
                  let action = ClickAction(rawValue: raw) else {
                return .modeDefault
            }
            return action
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.singleClickAction)
            notifyChanged()
        }
    }
    
    public var doubleClickAction: ClickAction {
        get {
            guard let raw = defaults.string(forKey: Keys.doubleClickAction),
                  let action = ClickAction(rawValue: raw) else {
                return .nextTrack
            }
            return action
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.doubleClickAction)
            notifyChanged()
        }
    }
    
    public var tripleClickAction: ClickAction {
        get {
            guard let raw = defaults.string(forKey: Keys.tripleClickAction),
                  let action = ClickAction(rawValue: raw) else {
                return .prevTrack
            }
            return action
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.tripleClickAction)
            notifyChanged()
        }
    }
    
    public var longPressAction: ClickAction {
        get {
            guard let raw = defaults.string(forKey: Keys.longPressAction),
                  let action = ClickAction(rawValue: raw) else {
                return .cycleMode
            }
            return action
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.longPressAction)
            notifyChanged()
        }
    }
    
    public var sensitivity: Double {
        get { defaults.double(forKey: Keys.sensitivity) }
        set {
            defaults.set(newValue, forKey: Keys.sensitivity)
            notifyChanged()
        }
    }
    
    public var invertRotation: Bool {
        get { defaults.bool(forKey: Keys.invertRotation) }
        set {
            defaults.set(newValue, forKey: Keys.invertRotation)
            notifyChanged()
        }
    }
    
    public var showHUD: Bool {
        get { defaults.bool(forKey: Keys.showHUD) }
        set {
            defaults.set(newValue, forKey: Keys.showHUD)
            notifyChanged()
        }
    }
    
    public var hudPosition: HUDPosition {
        get {
            guard let raw = defaults.string(forKey: Keys.hudPosition),
                  let pos = HUDPosition(rawValue: raw) else {
                return .bottomCenter
            }
            return pos
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.hudPosition)
            notifyChanged()
        }
    }
    
    public var modifierOverridesEnabled: Bool {
        get { defaults.bool(forKey: Keys.modifierOverrides) }
        set {
            defaults.set(newValue, forKey: Keys.modifierOverrides)
            notifyChanged()
        }
    }
    
    public var launchAtLogin: Bool {
        get { defaults.bool(forKey: Keys.launchAtLogin) }
        set {
            defaults.set(newValue, forKey: Keys.launchAtLogin)
            notifyChanged()
        }
    }
    
    public var menuBarIconStyle: MenuBarIconStyle {
        get {
            guard let raw = defaults.string(forKey: Keys.menuBarIconStyle),
                  let style = MenuBarIconStyle(rawValue: raw) else {
                return .rotaryKnob
            }
            return style
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.menuBarIconStyle)
            notifyChanged()
        }
    }
    
    private func notifyChanged() {
        NotificationCenter.default.post(name: KnobSettings.settingsChangedNotification, object: self)
    }
}
