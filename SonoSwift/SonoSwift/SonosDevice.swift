//
//  SonosDevice.swift
//  Sonos_Volume_Control
//
//  Created by Alexander Heinrich on 14.03.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa
import SWXMLHash

public protocol SonosDeviceDelegate {
    func didUpdateActiveState(forSonos sonos: SonosDevice, isActive: Bool)
}

public class SonosDevice: Equatable, Hashable {
    //   MARK:  Properties
    
    /// Name of the room
    public private(set) var roomName: String
    /// Name of the device
    public private(set) var deviceName: String
    /// Model name of the device
    public private(set) var modelName: String = ""
    /// URL where to find it
    public private(set) var url: URL
    /// IP address of the device
    public private(set) var ip: String
    /// Port to address the speaker
    public private(set) var port: Int = 1400
    /// UDN contains an id
    public private(set) var udn:String
    /// The type description of the device
    public var lastDiscoveryDate: Date = Date()
    /// Device Type string
    public private(set) var deviceType: String
    /// The description of the speaker stored as XML
    public private(set) var descriptionXML: XMLIndexer?
    /// If true the box is an active (controllable) speaker
    public var active: Bool = true
    /// The speakers current colume
    public private(set) var currentVolume = 0
    private var updateVolume = 0
    private var isUpdatingVolume = false
    private var lastVolumeSet = Date()
    /// State if the device is playing or not
    public var playState = PlayState.notSet
    /// If true the speaker is muted
    public private(set) var muted = false
    /// Track info of the currently playing song / radio
    public private(set) var trackInfo: SonosTrackInfo?
    
    /// The speakers current group state
    public private(set) var groupState: SonosGroupState = SonosGroupState()
    
    /// Speakers device info
    public private(set) var deviceInfo: SonosDeviceInfo?
    
    public var delegate: SonosDeviceDelegate?
    
    /// A timer which waits a short time before the volume will be updated
    private var volumeTimer: Timer?
    
    /// String shown in the UI
    public var readableName:String {
//        if let zoneName = self.deviceInfo?.zoneName {
//            return "\(zoneName) - \(deviceName)"
//        }
        var rName = "\(roomName) - \(deviceName)"
        if pairedSpeakers == 1 {
            rName += " (\(NSLocalizedString("Stereo", comment: "")))"
        }else if pairedSpeakers > 1 {
            // Sound system setup
            rName = "\(roomName) - \(NSLocalizedString("Home theater", comment: "Device name when using a sound system"))"
        }
        return rName
    }
    
    
    /// This value counts the number of paired speakers
    internal var pairedSpeakers = 0 {
        didSet {
            dPrint("Paired speakers: \(pairedSpeakers)")
        }
    }
    
    
    //   MARK: - Init
    
    public init(xml: XMLIndexer, url: URL,_ completion: @escaping(_ sonos: SonosDevice)->Void) {
        let device = xml["root"]["device"]
        let displayName = device["displayName"].element?.text
        let roomName = device["roomName"].element?.text
        self.roomName = roomName ?? "unknown"
        self.deviceName = displayName ?? "unknown"
        self.deviceType = device["deviceType"].element?.text ?? "unknown"
        self.url = url
        self.ip = url.host ?? "127.0.0.0"
        self.descriptionXML = xml
        self.udn = device["UDN"].element?.text ?? "no-udn"
        
        if let modelName = device["modelName"].element?.text {
            self.modelName = modelName
        }
        
        self.updateAll({ completion(self) })
        self.getNetworkTopology()
    }
    
    public init(roomName:String, deviceName:String, url:URL, ip: String, udn: String, deviceInfo: SonosDeviceInfo, groupState: SonosGroupState) {
        self.roomName = roomName
        self.deviceName = deviceName
        self.url = url
        self.ip = ip
        self.udn = udn
        self.deviceType = "unknown"
        
        self.deviceInfo = deviceInfo
        self.groupState = groupState
    }
    
    //MARK: - General Info
    
    public var isGroupCoordinator: Bool {
        return self.groupState.deviceIds.first == self.deviceInfo?.localUID
    }
    
    public var isSpeaker: Bool {
        return self.deviceType.contains("Player")
    }
    
    public var canSetVolume: Bool {
        return self.deviceType.contains("Player")
    }
    
    public func getNetworkTopology() {
        SonosCommand.downloadNetworkTopologyInfo(sonos: self) { (data) in
            guard let xml = self.parseXml(data: data) else {return}
        }
    }
    
    //    MARK: - Interactions
    
    /**
     Set the volume of the Sonos device
     
     - Parameters:
     - volume: between 0 and 100
     */
    public func setVolume(volume: Int){
        guard lastVolumeSet.timeIntervalSinceNow < -0.1 else {
            self.currentVolume = volume
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                guard self.currentVolume != self.updateVolume else {return}
                self.setVolume(volume: self.currentVolume)
            }
            return
        }
        //Update the volume
        isUpdatingVolume = true
        lastVolumeSet = Date()
        
        updateVolume = volume
        
        if updateVolume < 0 {
            updateVolume = 0
        }else if updateVolume > 100 {
            updateVolume = 100
        }
        
        
        self.currentVolume = updateVolume
        
        let command = SonosCommand(endpoint: .rendering_endpoint, action: .setVolume, service: .rendering_service)
        command.put(key: "InstanceID", value: "0")
        command.put(key: "Channel", value: "Master")
        command.put(key: "DesiredVolume", value: String(updateVolume))
        command.execute(sonos: self) { (_) in
        }
        
        
        if self.muted && updateVolume > 0 {
            //Unmute speaker
            self.setMute(muted: false)
        }
        
        dPrint("Updating volume to: ", updateVolume)
    }
    
    /**
     Set the speaker to be muted or not
     
     - Parameters:
     - muted: If true the speaker will be muted
     */
    public func setMute(muted: Bool) {
        let command =  SonosCommand(endpoint: .rendering_endpoint, action: .setMute, service: .rendering_service)
        command.put(key: "InstanceID", value: "0")
        command.put(key: "Channel", value: "Master")
        command.put(key: "DesiredMute", value: muted ? "1" : "0")
        command.execute(sonos: self)
        self.muted = muted
    }
    
    public func play() {
        let command = SonosCommand(endpoint: .transport_endpoint, action: .play, service: .transport_service)
        command.put(key: "InstanceID", value: "0")
        command.put(key: "Speed", value: "1")
        command.execute(sonos: self)
        self.playState = .playing
    }
    
    /**
     Pause the current song
    */
    public func pause() {
        let command = SonosCommand(endpoint: .transport_endpoint, action: .pause, service: .transport_service)
        command.put(key: "InstanceID", value: "0")
        command.put(key: "Speed", value: "1")
        command.execute(sonos: self)
        self.playState = .paused
    }
    
    /**
     Play the next song
    */
    public func next() {
        let command = SonosCommand(endpoint: .transport_endpoint, action: .next, service: .transport_service)
        command.put(key: "InstanceID", value: "0")
        command.put(key: "Speed", value: "1")
        command.execute(sonos: self)
    }
    
    /**
     Play the previous song
    */
    public func previous() {
        let command = SonosCommand(endpoint: .transport_endpoint, action: .prev, service: .transport_service)
        command.put(key: "InstanceID", value: "0")
        command.put(key: "Speed", value: "1")
        command.execute(sonos: self)
    }
    
    @objc public func activateDeactivate(button: NSButton) {
        if button.state == .on {
            self.active = true
        }else if button.state == .off {
            self.active = false
        }
        
        self.delegate?.didUpdateActiveState(forSonos: self, isActive: self.active)
    }
    
    //  MARK: - Updates
    
    public func update(withXML xml: XMLIndexer, url: URL) {
        let device = xml["root"]["device"]
        let displayName = device["displayName"].element?.text
        let roomName = device["roomName"].element?.text
        self.roomName = roomName ?? "unknown"
        self.deviceName = displayName ?? "unknown"
        self.deviceType = device["deviceType"].element?.text ?? "unknown"
        self.url = url
        self.ip = url.host ?? "127.0.0.0"
        self.descriptionXML = xml
        self.udn = device["UDN"].element?.text ?? "no-udn"
        self.lastDiscoveryDate = Date()
        
        self.updateAll({})
    }
    
    public func updateAll(_ completion: @escaping ()->Void) {
        //      Update the speakers state
        self.pairedSpeakers = 0
        self.updateCurrentVolume()
        self.getPlayState()
        self.updateCurrentTrack()
        
        //      Get the device info and update the group state
        SonosCommand.downloadSpeakerInfo(sonos: self) { (data) in
            guard let xml = self.parseXml(data: data) else {return}
            self.deviceInfo = SonosDeviceInfo(xml: xml)
            self.updateZoneGroupState({
                DispatchQueue.main.async {completion()}
            })
        }
    }
    
    /**
     Update the speakers group state
     */
    public func updateZoneGroupState(_ completion: @escaping ()->Void) {
        let command = SonosCommand(endpoint: .zone_group_endpoint, action: .getZoneAttributes, service: .zone_group_service)
        command.execute(sonos: self, { (data) in
            guard let xml = self.parseXml(data: data) else {return}
            self.groupState = SonosGroupState(xml: xml)
            completion()
        })
    }
    
    public func updateCurrentVolume() {
        getVolume { (volume) in }
    }
    
    
    public func updateMute() {
        let command = SonosCommand(endpoint: .rendering_endpoint, action: .getMute, service: .rendering_service)
        command.put(key: "InstanceID", value: "0")
        command.put(key: "Channel", value: "Master")
        command.execute(sonos: self) { (data) in
            guard let xml = self.parseXml(data: data),
             let muteText = xml["s:Envelope"]["s:Body"]["u:GetMuteResponse"]["CurrentMute"].element?.text else {return}
            
            self.muted = muteText == "1"
        }
    }
    
    /**
     Get the speakers current volume
    */
    public func getVolume(_ completion:@escaping (_ volume: Int)->Void) {
        //Update the mute state, too
        self.updateMute()
        
        let command = SonosCommand(endpoint: .rendering_endpoint, action: .getVolume, service: .rendering_service)
        command.put(key: "InstanceID", value: "0")
        command.put(key: "Channel", value: "Master")
        
        command.execute(sonos: self, { data in
            guard let data = data else {return}
            let xml = SWXMLHash.parse(data)
            //Get the volume out of the xml
            if let volumeText = xml["s:Envelope"]["s:Body"]["u:GetVolumeResponse"]["CurrentVolume"].element?.text,
                let volume = Int(volumeText) {
                self.currentVolume = volume
            }
            DispatchQueue.main.async {completion(self.currentVolume)}
        })
    }
    
    /**
     Get speakers the play state
    */
    public func getPlayState(_ completion: ((_ state: PlayState)->Void)? = nil) {
        let command = SonosCommand(endpoint: .transport_endpoint, action: .getTransportInfo, service: .transport_service)
        command.put(key: "InstanceID", value: "0")
        command.execute(sonos: self) { (data) in
            guard let data = data else {return}
            let xml = SWXMLHash.parse(data)
            guard let playStateString = xml["s:Envelope"]["s:Body"]["u:GetTransportInfoResponse"]["CurrentTransportState"].element?.text else {return}
            self.playState = PlayState(rawValue: playStateString) ?? .notSet
            DispatchQueue.main.async {
                completion?(self.playState)
            }
        }
    }
    
    /**
     Update the current track and return it in the completion handler
     
     - Parameters:
     - completion: Callback contains TrackInfo
     */
    public func updateCurrentTrack(_ completion: ((_ trackInfo: SonosTrackInfo)->Void)?=nil) {
        let command = SonosCommand(endpoint: .transport_endpoint, action: .get_position_info, service: .transport_service)
        command.put(key:"InstanceID",value: "0")
        command.put(key:"Channel",value: "Master")
        command.execute(sonos: self) { (data) in
            guard let xml = self.parseXml(data: data),
            let metaDataText = xml["s:Envelope"]["s:Body"]["u:GetPositionInfoResponse"]["TrackMetaData"].element?.text,
            metaDataText != "NOT_IMPLEMENTED" else {return}
            let metadataXML = SWXMLHash.parse(metaDataText)
            let trackInfo = SonosTrackInfo(xml: metadataXML["DIDL-Lite"]["item"])
            self.trackInfo = trackInfo
            
            DispatchQueue.main.async {
                completion?(trackInfo)
            }
        }
        
    }
    
    
    /// Get Media Info. This is only useful for radio / podcasts / stations. Does not give any info about tracks
    ///
    /// - Parameter completion: completion handler
    func getMediaInfo(_ completion: ((_ mediaInfo: SonosMediaInfo?)->Void)?=nil) {
        let command = SonosCommand(endpoint: .transport_endpoint, action: .get_media_info, service: .transport_service)
        command.put(key:"InstanceID",value: "0")
        
        command.execute(sonos: self) { (data) in
            guard let xml = self.parseXml(data: data)
                else {completion?(nil); return}
            
            let mediaInfo = SonosMediaInfo(xml: xml)

            DispatchQueue.main.async {
                completion?(mediaInfo)
            }
        }
    }
    
//    func getQueue(start: Int, count: Int) {
//        let command = SonosCommand(endpoint: .content_directory_endpoint, action: .browse, service: .content_directory_service)
//        command.put(key:"ObjectID",value: "Q:0")
//        command.put(key:"BrowseFlag",value: "BrowseDirectChildren")
//        command.put(key:"Filter",value: "dc:title,res,dc:creator,upnp:artist,upnp:album,upnp:albumArtURI")
//        command.put(key:"StartingIndex",value: String(start))
//        command.put(key:"RequestedCount",value: String(count))
//        command.put(key:"SortCriteria",value: "")
//        command.execute(sonos: self) { (data) in
//            guard let xml = self.parseXml(data: data) else {return}
//        }
//    }
    
    internal func parseXml(data: Data?) -> XMLIndexer? {
        guard let data = data else {return nil}
        let xml = SWXMLHash.parse(data)
        return xml
    }
    
    public static func ==(l:SonosDevice, r:SonosDevice) -> Bool {
        return l.udn == r.udn
    }
    
    public var hashValue: Int {
        return self.deviceInfo?.localUID.hashValue ?? "no-id".hashValue
    }
    
    var debugDescription: String {
        let debugString = """
        \(readableName)
        ----------------------------------
        Model name: \(modelName)
        Device ip: \(ip)
        UDN: \(udn)
        Device Type: \(deviceType)
        isActive: \(active)
        current Volume: \(currentVolume)
        Play state: \(playState)
        \(trackInfo?.debugDescription ?? "No Track info")
        \(groupState.debugDescription ?? "No group state")
        \(deviceInfo?.debugDescription ?? "No device info")
        """
        
        return debugString
    }
    
    
}
