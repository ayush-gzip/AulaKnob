import Foundation
import Cocoa
import IOKit

public final class BrightnessController {
    public static let shared = BrightnessController()
    
    private var estimatedBrightness: Float = 0.5
    
    private typealias DisplayServicesGetBrightnessFunc = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias DisplayServicesSetBrightnessFunc = @convention(c) (CGDirectDisplayID, Float) -> Int32
    
    private var getBrightnessFn: DisplayServicesGetBrightnessFunc?
    private var setBrightnessFn: DisplayServicesSetBrightnessFunc?
    
    private init() {
        if let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY) {
            if let getSym = dlsym(handle, "DisplayServicesGetBrightness") {
                getBrightnessFn = unsafeBitCast(getSym, to: DisplayServicesGetBrightnessFunc.self)
            }
            if let setSym = dlsym(handle, "DisplayServicesSetBrightness") {
                setBrightnessFn = unsafeBitCast(setSym, to: DisplayServicesSetBrightnessFunc.self)
            }
        }
        _ = getBrightness()
    }
    
    public func getBrightness() -> Float {
        if let getFn = getBrightnessFn {
            var b: Float = 0.0
            if getFn(CGMainDisplayID(), &b) == 0 {
                estimatedBrightness = b
                return b
            }
        }
        return estimatedBrightness
    }
    
    @discardableResult
    public func setBrightness(_ value: Float) -> Float {
        let clamped = max(0.0, min(1.0, value))
        estimatedBrightness = clamped
        
        if let setFn = setBrightnessFn {
            _ = setFn(CGMainDisplayID(), clamped)
        }
        return clamped
    }
    
    public func adjustBrightness(delta: Float) -> Float {
        if delta > 0 {
            postBrightnessKey(key: 2) // NX_KEYTYPE_BRIGHTNESS_UP
        } else {
            postBrightnessKey(key: 3) // NX_KEYTYPE_BRIGHTNESS_DOWN
        }
        let current = getBrightness()
        let newB = max(0.0, min(1.0, current + delta))
        estimatedBrightness = newB
        return newB
    }
    
    private func postBrightnessKey(key: Int) {
        for down in [true, false] {
            let flags = down ? 0xa00 : 0xb00
            let data1 = (key << 16) | flags
            
            let ev = NSEvent.otherEvent(
                with: .systemDefined,
                location: .zero,
                modifierFlags: [],
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                subtype: 8,
                data1: data1,
                data2: -1
            )
            if let cgEv = ev?.cgEvent {
                cgEv.post(tap: .cghidEventTap)
            }
        }
    }
}
