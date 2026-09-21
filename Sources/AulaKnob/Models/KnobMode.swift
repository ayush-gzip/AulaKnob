import Foundation

public enum KnobMode: String, CaseIterable, Codable {
    case volume = "volume"
    case brightness = "brightness"
    case scroll = "scroll"
    case spaces = "spaces"
    case tabs = "tabs"
    case scrub = "scrub"
    case appSwitch = "appSwitch"
    case passthrough = "passthrough"
    
    public var displayName: String {
        switch self {
        case .volume: return "Volume & Media"
        case .brightness: return "Screen Brightness"
        case .scroll: return "Smooth Scroll & Zoom"
        case .spaces: return "Desktop Spaces"
        case .tabs: return "Browser / Editor Tabs"
        case .scrub: return "Video / Media Scrubbing"
        case .appSwitch: return "App Switcher (Cmd+Tab)"
        case .passthrough: return "Default (Passthrough)"
        }
    }
    
    public var sfSymbol: String {
        switch self {
        case .volume: return "speaker.wave.3.fill"
        case .brightness: return "sun.max.fill"
        case .scroll: return "arrow.up.and.down"
        case .spaces: return "macwindow.on.rectangle"
        case .tabs: return "square.stack.3d.forward.dottedline.fill"
        case .scrub: return "goforward.5"
        case .appSwitch: return "square.grid.2x2.fill"
        case .passthrough: return "keyboard"
        }
    }
    
    public var menuIcon: String {
        switch self {
        case .volume: return "🔊"
        case .brightness: return "☀️"
        case .scroll: return "📜"
        case .spaces: return "🪟"
        case .tabs: return "📑"
        case .scrub: return "⏩"
        case .appSwitch: return "🔀"
        case .passthrough: return "⌨️"
        }
    }
    
    public var description: String {
        switch self {
        case .volume: return "Rotate: Volume ± | Click: Play/Pause | Double-click: Next track"
        case .brightness: return "Rotate: Brightness ± | Click: Toggle 50%/100%"
        case .scroll: return "Rotate: Scroll Up/Down | Click: Toggle Zoom mode"
        case .spaces: return "Rotate: Switch Spaces (Ctrl+Left/Right) | Click: Mission Control"
        case .tabs: return "Rotate: Switch Tabs (Cmd+Shift+[/]) | Click: Close tab (Cmd+W)"
        case .scrub: return "Rotate: Scrub 5s (Left/Right) | Click: Play/Pause (Space)"
        case .appSwitch: return "Rotate: Cycle Apps (Cmd+Tab) | Click: Select Active App"
        case .passthrough: return "Original macOS standard media key handling"
        }
    }
    
    public var nextMode: KnobMode {
        let all = KnobMode.allCases.filter { $0 != .passthrough }
        guard let idx = all.firstIndex(of: self) else { return .volume }
        let nextIdx = (idx + 1) % all.count
        return all[nextIdx]
    }
    
    public var previousMode: KnobMode {
        let all = KnobMode.allCases.filter { $0 != .passthrough }
        guard let idx = all.firstIndex(of: self) else { return .volume }
        let prevIdx = (idx - 1 + all.count) % all.count
        return all[prevIdx]
    }
}

public enum ClickAction: String, CaseIterable, Codable {
    case cycleMode = "cycleMode"
    case cycleModeBackwards = "cycleModeBackwards"
    case playPause = "playPause"
    case muteUnmute = "muteUnmute"
    case nextTrack = "nextTrack"
    case prevTrack = "prevTrack"
    case missionControl = "missionControl"
    case showDesktop = "showDesktop"
    case toggleZoom = "toggleZoom"
    case closeTab = "closeTab"
    case newTab = "newTab"
    case spacebar = "spacebar"
    case modeDefault = "modeDefault"
    case none = "none"
    
    public var displayName: String {
        switch self {
        case .modeDefault: return "Mode Default (Context-sensitive)"
        case .cycleMode: return "Cycle to Next Mode"
        case .cycleModeBackwards: return "Cycle to Previous Mode"
        case .playPause: return "Play / Pause Media"
        case .muteUnmute: return "Mute / Unmute Volume"
        case .nextTrack: return "Next Track"
        case .prevTrack: return "Previous Track"
        case .missionControl: return "Mission Control"
        case .showDesktop: return "Show Desktop"
        case .toggleZoom: return "Toggle Scroll / Zoom"
        case .closeTab: return "Close Current Tab (Cmd+W)"
        case .newTab: return "New Tab (Cmd+T)"
        case .spacebar: return "Press Spacebar"
        case .none: return "Do Nothing"
        }
    }
}

public enum HUDPosition: String, CaseIterable, Codable {
    case bottomCenter = "bottomCenter"
    case topCenter = "topCenter"
    case center = "center"
    
    public var displayName: String {
        switch self {
        case .bottomCenter: return "Bottom Center (Modern)"
        case .topCenter: return "Top Center"
        case .center: return "Screen Center (Classic)"
        }
    }
}
