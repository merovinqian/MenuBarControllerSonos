//
//  AudioHandler.swift
//  Menu Bar Controller for Sonos
//
//  Created by Alexander Heinrich on 25.07.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa
import AVFoundation
import MediaPlayer
import SonoSwift

class SystemAudioRemoteHandler: NSObject {
    
    static let shared: SystemAudioRemoteHandler! = SystemAudioRemoteHandler()
    
    var currentTrackInfo: SonosTrackInfo?
    var currentGroup: SonosSpeakerGroup?
    var audioPlayer: AVAudioPlayer?
    
    private override init() {
        super.init()
        
        if #available(OSX 10.12.2, *) {
            self.setupRemote()
        } else {
            // Fallback on earlier versions
            dPrint("System does not support TouchBar and Notification Center widgets")
        }
    }

    
    /// Update the system output in notification center and on the touchbar to show the current track and playstate
    ///
    /// - Parameters:
    ///   - trackInfo: Sonos current track info with title
    ///   - playState: Sonos group's current play state
    ///   - group: The group which is currently selected in the app
    func updateSystemPlayingInfo(trackInfo: SonosTrackInfo, playState: PlayState, group: SonosSpeakerGroup) {
        self.currentGroup = group
        self.currentTrackInfo = trackInfo
        
        if trackInfo.isPlayingRadio{
            //Get Media Info
            group.getMediaInfo { (mediaInfo) in
                if let title = mediaInfo?.mediaTitle {
                    let nowPlayingInfo = [MPMediaItemPropertyTitle : title]
                    self.updateNowPlayingInfo(nowPlayingInfo)
                }
            }
            
        }else {
            var nowPlayingInfo: [String : String]!
            
            if trackInfo.artist != "Unkown Artist" && trackInfo.title != "Unknown Title"{
                nowPlayingInfo = [MPMediaItemPropertyArtist : trackInfo.artist,  MPMediaItemPropertyTitle : trackInfo.title]
            }else {
                nowPlayingInfo = [MPMediaItemPropertyTitle : trackInfo.trackText()]
            }
            
            self.updateNowPlayingInfo(nowPlayingInfo)
        }
        
        if #available(OSX 10.12.2, *) {
            MPNowPlayingInfoCenter.default().playbackState = self.playbackState(forPlayState: playState)
        }
    }
    
    func updateNowPlayingInfo(_ nowPlayingInfo: [String : String]!) {
        if #available(OSX 10.12.2, *) {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        } else {
            // Fallback on earlier versions
            dPrint("System does not support TouchBar and Notification Center widgets")
        }
    }
    
    public func handlePlayPause() {
        guard let playState = currentGroup?.currentPlayState else {return}
        
        switch playState {
        case .playing:
            currentGroup?.pause()
        case .paused:
            currentGroup?.play()
        case .stopped:
            currentGroup?.play()
        default:
            currentGroup?.play()
        }
        
        if let trackInfo = currentTrackInfo,
            let group = currentGroup,
            let ps = group.currentPlayState {
            self.updateSystemPlayingInfo(trackInfo: trackInfo, playState: ps, group: group)
        }
        
    }
    
    public func handleNext() {
        currentGroup?.next()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.updateTitleAndMediaInfo()
        }
    }
    
    public func handlePrevious() {
        currentGroup?.previous()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.updateTitleAndMediaInfo()
        }
    }
    
    private func updateTitleAndMediaInfo() {
        guard let group = self.currentGroup,
            let ps = group.currentPlayState else {return}
        
        group.updateCurrentTrack { (trackInfo) in
            self.updateSystemPlayingInfo(trackInfo: trackInfo, playState: ps, group: group)
        }
    }
    
    @available(OSX 10.12.2, *)
    /// Get the MPNowPlayingPlaybackState for a Sonos PlayState
    ///
    /// - Parameter ps: PlayState
    /// - Returns: MPNowPlayingPlaybackState
    private func playbackState(forPlayState ps: PlayState) -> MPNowPlayingPlaybackState {
        switch ps {
        case .paused:
            return MPNowPlayingPlaybackState.paused
        case .playing:
            return MPNowPlayingPlaybackState.playing
        case .stopped:
            return MPNowPlayingPlaybackState.stopped
        case .error:
            return MPNowPlayingPlaybackState.interrupted
        default:
            return MPNowPlayingPlaybackState.unknown
        }
    }
    
    @available(OSX 10.12.2, *)
    
    /// Setup the system remote
    func setupRemote() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.currentGroup?.play()
            
            return MPRemoteCommandHandlerStatus.success
        }
        
        commandCenter.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.currentGroup?.pause()
            
            return MPRemoteCommandHandlerStatus.success
        }
        
        commandCenter.nextTrackCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.currentGroup?.next()
            
            return MPRemoteCommandHandlerStatus.success
        }
        
        commandCenter.previousTrackCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            self.currentGroup?.previous()
            
            return MPRemoteCommandHandlerStatus.success
        }
        
    }
    
    
}
