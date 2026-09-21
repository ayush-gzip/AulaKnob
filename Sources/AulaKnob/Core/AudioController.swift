import Foundation
import CoreAudio
import AudioToolbox
import Cocoa

public final class AudioController {
    public static let shared = AudioController()
    
    private init() {}
    
    private func getDefaultOutputDevice() -> AudioDeviceID? {
        var defaultOutputDeviceID = AudioDeviceID(0)
        var defaultOutputDeviceIDSize = UInt32(MemoryLayout.size(ofValue: defaultOutputDeviceID))
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &defaultOutputDeviceIDSize,
            &defaultOutputDeviceID
        )
        
        guard status == noErr, defaultOutputDeviceID != kAudioObjectUnknown else {
            return nil
        }
        return defaultOutputDeviceID
    }
    
    public func getVolume() -> Float {
        guard let deviceID = getDefaultOutputDevice() else { return 0.5 }
        
        var volume: Float32 = 0.0
        var volumeSize = UInt32(MemoryLayout.size(ofValue: volume))
        var volumePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            deviceID,
            &volumePropertyAddress,
            0,
            nil,
            &volumeSize,
            &volume
        )
        
        if status == noErr {
            return volume
        }
        
        // Fallback to master channel (0) if virtual main fails
        var masterAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 0
        )
        let masterStatus = AudioObjectGetPropertyData(
            deviceID,
            &masterAddress,
            0,
            nil,
            &volumeSize,
            &volume
        )
        return masterStatus == noErr ? volume : 0.5
    }
    
    @discardableResult
    public func setVolume(_ volume: Float) -> Float {
        let clamped = max(0.0, min(1.0, volume))
        guard let deviceID = getDefaultOutputDevice() else { return clamped }
        
        var vol = clamped
        let volumeSize = UInt32(MemoryLayout.size(ofValue: vol))
        var volumePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var status = AudioObjectSetPropertyData(
            deviceID,
            &volumePropertyAddress,
            0,
            nil,
            volumeSize,
            &vol
        )
        
        if status != noErr {
            var masterAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: 0
            )
            status = AudioObjectSetPropertyData(
                deviceID,
                &masterAddress,
                0,
                nil,
                volumeSize,
                &vol
            )
        }
        
        // If unmuting when volume raised
        if clamped > 0 && isMuted() {
            setMuted(false)
        }
        
        return clamped
    }
    
    public func adjustVolume(delta: Float) -> Float {
        let current = getVolume()
        let newVol = current + delta
        return setVolume(newVol)
    }
    
    public func isMuted() -> Bool {
        guard let deviceID = getDefaultOutputDevice() else { return false }
        var mute: UInt32 = 0
        var muteSize = UInt32(MemoryLayout.size(ofValue: mute))
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &muteSize,
            &mute
        )
        return status == noErr && mute == 1
    }
    
    public func setMuted(_ muted: Bool) {
        guard let deviceID = getDefaultOutputDevice() else { return }
        var mute: UInt32 = muted ? 1 : 0
        let muteSize = UInt32(MemoryLayout.size(ofValue: mute))
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectSetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            muteSize,
            &mute
        )
    }
    
    public func toggleMute() -> Bool {
        let current = isMuted()
        setMuted(!current)
        return !current
    }
    
    // Media Playback Control
    public func playPause() {
        postMediaKey(key: 16) // NX_KEYTYPE_PLAY
    }
    
    public func nextTrack() {
        postMediaKey(key: 17) // NX_KEYTYPE_NEXT
    }
    
    public func previousTrack() {
        postMediaKey(key: 18) // NX_KEYTYPE_PREVIOUS
    }
    
    private func postMediaKey(key: Int) {
        // Send key down and key up
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
