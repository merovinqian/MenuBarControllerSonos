//
//  SonosSpeakerGroup.swift
//  Menu Bar Controller for Sonos
//
//  Created by Alexander Heinrich on 24.03.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa

public protocol SonosSpeakerGroupDelegate {
    func didChangeActiveState(group: SonosSpeakerGroup)
}

//TODO: Add delegate
public class SonosSpeakerGroup: Hashable {
    public private(set) var name: String
    public let groupID: String
    private (set) var speakers: Set<SonosDevice> = Set()
    private var speakerOrder: [String]
    public var delegate: SonosSpeakerGroupDelegate?
    
    public var isActive: Bool = false
    
    public var trackInfo: SonosTrackInfo? {
        return self.mainSpeaker?.trackInfo
    }
    
    public init?(groupID: String, firstSpeaker: SonosDevice) {
        guard firstSpeaker.groupState.isEmpty == false else {return nil}
        
        self.groupID = groupID
        self.speakerOrder = firstSpeaker.groupState.deviceIds
        self.name = firstSpeaker.groupState.name
        self.addSpeaker(firstSpeaker)
    }
    
    /// Get the group's controller
    private var mainSpeaker: SonosDevice? {
        if let main = speakers.first(where: {speakerOrder.first == $0.deviceInfo?.localUID}) {
            return main
        }
        return self.speakers.first
    }
    
    private var groupVolume: Int {
        guard speakers.count > 0 else {return 1}
        
        var volume = 0
        for sonos in speakers {
            volume += sonos.currentVolume
        }
        volume = volume / speakers.count
        
        return volume > 0 ? volume : 1
    }
    
    public func getGroupVolume(_ completion:@escaping (_ vol: Int)->Void ) {
        var count = speakers.count
        for sonos in speakers {
            sonos.getVolume({ (_) in
                count -= 1
                if count == 0 {
                    completion(self.groupVolume)
                }
            })
        }
    }
    
    public func addSpeaker(_ sonos: SonosDevice) {
        guard sonos.groupState.groupID == self.groupID else {return}
        
        self.speakers.insert(sonos)
        if !sonos.groupState.name.isEmpty && self.name != sonos.groupState.name {
            self.name = sonos.groupState.name
        }
    }
    
    public func removeIfGroupChanged(_ sonos: SonosDevice) {
        guard sonos.groupState.groupID != self.groupID else {return}
        
        self.speakers.remove(sonos)
    }
    
    public func remove(sonos: SonosDevice) {
        self.speakers.remove(sonos)
    }
    
    @objc public  func activateDeactivate(button: NSButton) {
        if button.state == .on {
            self.isActive = true
        }else if button.state == .off {
            self.isActive = false
        }
        
        self.delegate?.didChangeActiveState(group: self)
    }
    
    public func setVolume(volume: Int){
        let groupVolume = self.groupVolume
        let increaseVol = volume - groupVolume
        for sonos in speakers {
            let currentVolume = sonos.currentVolume > 0 ? sonos.currentVolume : 1
            let updatedVolume = currentVolume + increaseVol
            sonos.setVolume(volume: updatedVolume)
        }
    }

    public func setMute(muted: Bool) {
        for sonos in speakers {
            sonos.setMute(muted: muted)
        }
    }
    
    public func play() {
        if let main = self.mainSpeaker {
            main.play()
        }else {
            self.speakers.forEach({$0.play()})
        }
    }
    
    public func pause() {
        if let main = self.mainSpeaker {
            main.pause()
        }else {
            self.speakers.forEach({$0.pause()})
        }
    }
    
    public func next() {
        if let main = self.mainSpeaker {
            main.next()
        }else {
            self.speakers.forEach({$0.next()})
        }
    }
    
    public func previous() {
        if let main = self.mainSpeaker {
            main.previous()
        }else {
            self.speakers.forEach({$0.previous()})
        }
    }
    
    /**
     Get groups the play state
     */
    public func getPlayState(_ completion: ((_ state: PlayState)->Void)? = nil) {
        mainSpeaker?.getPlayState(completion)
    }
    
    public var currentPlayState: PlayState? {
        return self.mainSpeaker?.playState
    }
    
    /**
     Update the current track and return it in the completion handler
     
     - Parameters:
     - completion: Callback contains TrackInfo
     */
    public func updateCurrentTrack(_ completion: ((_ trackInfo: SonosTrackInfo)->Void)?=nil) {
        self.mainSpeaker?.updateCurrentTrack(completion)
    }
    
    public func getMediaInfo(_ completion: ((_ mediaInfo: SonosMediaInfo?)->Void)?=nil) {
        self.mainSpeaker?.getMediaInfo(completion)
    }
    
    
    public var hashValue: Int {
        return self.groupID.hashValue
    }
    
    public static func ==(l:SonosSpeakerGroup, r:SonosSpeakerGroup) -> Bool {
        return l.groupID == r.groupID
    }
    
}
