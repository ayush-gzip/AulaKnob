import Foundation
import Cocoa

public enum MenuBarIconStyle: String, CaseIterable, Codable {
    case rotaryKnob = "rotaryKnob"
    case modeSymbol = "modeSymbol"
    case knobWithLabel = "knobWithLabel"
    
    public var displayName: String {
        switch self {
        case .rotaryKnob: return "Rotary Knob Dial (Minimal)"
        case .modeSymbol: return "Active Mode Symbol (Dynamic)"
        case .knobWithLabel: return "Knob Dial + Mode Tag"
        }
    }
}

public struct KnobIconGenerator {
    
    /// Generates a pixel-perfect template vector image of a mechanical rotary knob for macOS menu bar
    public static func createKnobIcon(mode: KnobMode, style: MenuBarIconStyle) -> NSImage {
        switch style {
        case .rotaryKnob:
            return drawRotaryKnob(angleDegrees: angleForMode(mode))
        case .modeSymbol:
            return createModeSymbolImage(mode: mode)
        case .knobWithLabel:
            return drawKnobWithLabel(mode: mode)
        }
    }
    
    private static func angleForMode(_ mode: KnobMode) -> CGFloat {
        switch mode {
        case .volume: return 45.0
        case .brightness: return 90.0
        case .scroll: return 135.0
        case .spaces: return 180.0
        case .tabs: return 225.0
        case .scrub: return 270.0
        case .appSwitch: return 315.0
        case .passthrough: return 0.0
        }
    }
    
    private static func drawRotaryKnob(angleDegrees: CGFloat) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        
        image.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }
        
        ctx.saveGState()
        
        let center = CGPoint(x: 9, y: 9)
        let outerRadius: CGFloat = 7.5
        let innerRadius: CGFloat = 5.2
        
        // 1. Outer Ring (Tactile rim / track)
        let outerPath = NSBezierPath()
        outerPath.appendArc(withCenter: center, radius: outerRadius, startAngle: 0, endAngle: 360)
        outerPath.lineWidth = 1.2
        NSColor.black.setStroke()
        outerPath.stroke()
        
        // 2. Inner Dial Disc
        let innerPath = NSBezierPath()
        innerPath.appendArc(withCenter: center, radius: innerRadius, startAngle: 0, endAngle: 360)
        innerPath.lineWidth = 1.0
        NSColor.black.setStroke()
        innerPath.stroke()
        
        // 3. Indicator Notch / Pointer
        let rad = (angleDegrees - 90) * .pi / 180.0
        let notchStart = CGPoint(
            x: center.x + (innerRadius - 2.8) * cos(rad),
            y: center.y - (innerRadius - 2.8) * sin(rad)
        )
        let notchEnd = CGPoint(
            x: center.x + (outerRadius + 0.5) * cos(rad),
            y: center.y - (outerRadius + 0.5) * sin(rad)
        )
        
        let notchPath = NSBezierPath()
        notchPath.move(to: notchStart)
        notchPath.line(to: notchEnd)
        notchPath.lineWidth = 1.8
        notchPath.lineCapStyle = .round
        notchPath.stroke()
        
        // 4. Center dot
        let dotPath = NSBezierPath()
        dotPath.appendArc(withCenter: center, radius: 1.2, startAngle: 0, endAngle: 360)
        NSColor.black.setFill()
        dotPath.fill()
        
        ctx.restoreGState()
        image.unlockFocus()
        image.isTemplate = true
        return image
    }
    
    private static func createModeSymbolImage(mode: KnobMode) -> NSImage {
        var symbol = mode.sfSymbol
        
        // Choose the cleanest, most recognizable SF symbols for menu bar
        switch mode {
        case .volume: symbol = "speaker.wave.2.fill"
        case .brightness: symbol = "sun.max.fill"
        case .scroll: symbol = "arrow.up.and.down"
        case .spaces: symbol = "macwindow.on.rectangle"
        case .tabs: symbol = "rectangle.stack.fill"
        case .scrub: symbol = "waveform"
        case .appSwitch: symbol = "square.grid.2x2.fill"
        case .passthrough: symbol = "dial.low.fill"
        }
        
        if let img = NSImage(systemSymbolName: symbol, accessibilityDescription: mode.displayName) {
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
            if let configured = img.withSymbolConfiguration(config) {
                configured.isTemplate = true
                return configured
            }
        }
        
        return drawRotaryKnob(angleDegrees: angleForMode(mode))
    }
    
    private static func drawKnobWithLabel(mode: KnobMode) -> NSImage {
        let knob = drawRotaryKnob(angleDegrees: angleForMode(mode))
        let labelText: String
        switch mode {
        case .volume: labelText = "VOL"
        case .brightness: labelText = "BRT"
        case .scroll: labelText = "SCR"
        case .spaces: labelText = "SPC"
        case .tabs: labelText = "TAB"
        case .scrub: labelText = "MED"
        case .appSwitch: labelText = "APP"
        case .passthrough: labelText = "RAW"
        }
        
        let font = NSFont.monospacedSystemFont(ofSize: 9, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black
        ]
        let str = NSAttributedString(string: labelText, attributes: attrs)
        let strSize = str.size()
        
        let totalWidth = knob.size.width + 4 + strSize.width
        let size = NSSize(width: totalWidth, height: 18)
        let image = NSImage(size: size)
        
        image.lockFocus()
        knob.draw(at: NSPoint(x: 0, y: 0), from: NSRect(origin: .zero, size: knob.size), operation: .sourceOver, fraction: 1.0)
        str.draw(at: NSPoint(x: knob.size.width + 3, y: (18 - strSize.height) / 2))
        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
