import Foundation
import Cocoa

public final class KnobHUDController {
    public static let shared = KnobHUDController()
    
    private var window: NSWindow?
    private var visualEffectView: NSVisualEffectView?
    private var iconImageView: NSImageView?
    private var titleLabel: NSTextField?
    private var detailLabel: NSTextField?
    private var progressBar: NSProgressIndicator?
    private var dismissTimer: Timer?
    
    private init() {
        setupWindow()
    }
    
    private func setupWindow() {
        let width: CGFloat = 220
        let height: CGFloat = 85
        let rect = NSRect(x: 0, y: 0, width: width, height: height)
        
        let win = NSWindow(
            contentRect: rect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.isOpaque = false
        win.backgroundColor = .clear
        win.level = .floating
        win.ignoresMouseEvents = true
        win.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        win.hasShadow = true
        
        let effect = NSVisualEffectView(frame: rect)
        effect.material = .hudWindow
        effect.state = .active
        effect.blendingMode = .behindWindow
        effect.wantsLayer = true
        effect.layer?.cornerRadius = 18
        effect.layer?.masksToBounds = true
        effect.layer?.borderWidth = 1.0
        effect.layer?.borderColor = NSColor.white.withAlphaComponent(0.18).cgColor
        
        let iconView = NSImageView(frame: NSRect(x: 18, y: 22, width: 40, height: 40))
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.contentTintColor = .labelColor
        effect.addSubview(iconView)
        self.iconImageView = iconView
        
        let tLabel = NSTextField(frame: NSRect(x: 68, y: 46, width: 135, height: 20))
        tLabel.isBezeled = false
        tLabel.drawsBackground = false
        tLabel.isEditable = false
        tLabel.isSelectable = false
        tLabel.textColor = .secondaryLabelColor
        tLabel.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        effect.addSubview(tLabel)
        self.titleLabel = tLabel
        
        let dLabel = NSTextField(frame: NSRect(x: 68, y: 24, width: 135, height: 22))
        dLabel.isBezeled = false
        dLabel.drawsBackground = false
        dLabel.isEditable = false
        dLabel.isSelectable = false
        dLabel.textColor = .labelColor
        dLabel.font = NSFont.systemFont(ofSize: 16, weight: .bold)
        effect.addSubview(dLabel)
        self.detailLabel = dLabel
        
        let pBar = NSProgressIndicator(frame: NSRect(x: 68, y: 14, width: 135, height: 6))
        pBar.isIndeterminate = false
        pBar.minValue = 0.0
        pBar.maxValue = 1.0
        pBar.style = .bar
        effect.addSubview(pBar)
        self.progressBar = pBar
        
        win.contentView = effect
        self.visualEffectView = effect
        self.window = win
    }
    
    public func show(
        title: String,
        detail: String,
        progress: Float? = nil,
        iconName: String,
        mode: KnobMode
    ) {
        guard KnobSettings.shared.showHUD else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let win = self.window else { return }
            
            self.titleLabel?.stringValue = title.uppercased()
            self.detailLabel?.stringValue = detail
            
            if let img = NSImage(systemSymbolName: iconName, accessibilityDescription: title) {
                let config = NSImage.SymbolConfiguration(pointSize: 24, weight: .medium)
                self.iconImageView?.image = img.withSymbolConfiguration(config)
            } else {
                self.iconImageView?.image = NSImage(named: NSImage.networkName)
            }
            
            if let p = progress {
                self.progressBar?.isHidden = false
                self.progressBar?.doubleValue = Double(p)
                self.detailLabel?.frame = NSRect(x: 68, y: 26, width: 135, height: 20)
            } else {
                self.progressBar?.isHidden = true
                self.detailLabel?.frame = NSRect(x: 68, y: 20, width: 135, height: 24)
            }
            
            self.updateWindowPosition()
            
            self.dismissTimer?.invalidate()
            
            win.alphaValue = 1.0
            win.orderFront(nil)
            
            self.dismissTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: false) { [weak self] _ in
                guard let self = self, let win = self.window else { return }
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.25
                    win.animator().alphaValue = 0.0
                }, completionHandler: {
                    if win.alphaValue == 0.0 {
                        win.orderOut(nil)
                    }
                })
            }
        }
    }
    
    private func updateWindowPosition() {
        guard let win = window, let screen = NSScreen.main else { return }
        let screenRect = screen.visibleFrame
        let winSize = win.frame.size
        
        let x = screenRect.midX - (winSize.width / 2)
        var y = screenRect.minY + 90 // Default bottom center
        
        switch KnobSettings.shared.hudPosition {
        case .bottomCenter:
            y = screenRect.minY + 90
        case .topCenter:
            y = screenRect.maxY - winSize.height - 50
        case .center:
            y = screenRect.midY - (winSize.height / 2)
        }
        
        win.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
