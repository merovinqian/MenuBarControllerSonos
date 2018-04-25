//
//  SonosController.swift
//  Sonos_Volume_Control
//
//  Created by Alexander Heinrich on 08.04.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa
import SWXMLHash

public protocol SonosControllerDelegate {
    func didUpdateSpeakers()
    func didUpdateGroups()
}

public class SonosController {
    public static let shared = SonosController.init()
    public private(set) var sonosSystems = [SonosDevice]()
    private var unlistedSystems = Set<SonosDevice>()
    public private(set) var sonosGroups: [String : SonosSpeakerGroup] = [:]
    var lastDiscoveryDeviceList = [SonosDevice]()
    
    private let discovery: SSDPDiscovery = SSDPDiscovery.defaultDiscovery
    fileprivate var session: SSDPDiscoverySession?
    
    public var delegate: SonosControllerDelegate?
    
    public var activeGroup: SonosSpeakerGroup? {
        return self.sonosGroups.values.first(where: {$0.isActive})
    }
    
    private init() {
        //Show Demo only in demo target
    }
    
    //MARK: - Updating Sonos Players
    /**
     Add a device to the list of devices
     
     - Parameters:
     - sonos: The Sonos Device which was found and should be added
     */
    private func addDeviceToList(sonos: SonosDevice) {
        guard sonosSystems.contains(sonos) == false &&
            listOfUnallowedDevices.contains(sonos.modelName) == false else {return}
        
        //New sonos system. Add it to the list
        self.sonosSystems.append(sonos)
        
        self.updatedSpeakers()
    }
    
    private func updatedSpeakers() {
        self.sortSpeakers()
        self.delegate?.didUpdateSpeakers()
    }
    
    /**
     Remove old devices which have not been discovered in the last discovery session
     */
    private func removeOldDevices() {
        //Remove undiscovered devices
        //All devices which haven't been found on last discovery
        let undiscoveredDevices = self.sonosSystems.filter({self.lastDiscoveryDeviceList.contains($0) == false})
        for sonos in undiscoveredDevices {
            //Remove speaker from group
            if sonos.groupState.isEmpty == false {
                let deviceGroup = self.sonosGroups[sonos.groupState.groupID]
                deviceGroup?.remove(sonos: sonos)
            }
        }
        
        let lastDeviceSet = Set<SonosDevice>(self.lastDiscoveryDeviceList.filter({!listOfUnallowedDevices.contains($0.modelName)}))
        self.sonosSystems = Array(lastDeviceSet)

        self.updatedSpeakers()
        
        let groups = Array(self.sonosGroups.values)
        for group in groups {
            if group.speakers.count == 0 {
                //Remove it
                self.sonosGroups.removeValue(forKey: group.groupID)
            }
        }
        
        
    }
    
    /**
     Update the groups controllers
     
     - Parameters:
     - sonos: The Sonos speaker which should be added to the group
     */
    private func updateGroups(sonos: SonosDevice) {
        guard sonos.groupState.isEmpty == false else {return}

        let gId = sonos.groupState.groupID
        
        if let group = self.sonosGroups[gId] {
            group.addSpeaker(sonos)
        }else if let group = SonosSpeakerGroup(groupID: gId,firstSpeaker: sonos) {
            self.sonosGroups[gId] = group
        }
        
        //Remove empty groups
        let containedInGroups = Array(self.sonosGroups.values.filter({$0.speakers.contains(sonos)}))
        for group in containedInGroups {
            //Check where speaker has moved to
            group.removeIfGroupChanged(sonos)
            if group.speakers.count == 0 {
                //Remove group
                self.sonosGroups.removeValue(forKey: group.groupID)
            }
        }
        
        self.updatedGroups()
    }
    
    /// Update the groups so all speakers will be added to the correct group
    private func updateGroupSpeakers() {
        //The systems will be iterated and added to the correct group
        for sonos in self.sonosSystems {
            let gId = sonos.groupState.groupID
            guard sonos.groupState.isEmpty == false,
                let group = self.sonosGroups[gId] else {continue}
            //Check if the group contains the speaker already
            if group.speakers.contains(sonos) == false {
                group.addSpeaker(sonos)
            }
        }
    }
    
    private func updatedGroups() {
        self.updateGroupSpeakers()
        self.delegate?.didUpdateGroups()
    }
    
    /**
     Found a duplicate sonos. Check if the IP address has changed
     
     - Parameters:
     - idx: Index at which the equal sonos is placed in sCntrl.sonosSystems
     - sonos: The newly discovered sonos
     */
    private func replaceSonos(atIndex idx: Int, withSonos sonos: SonosDevice) {
        let eqSonos = sonosSystems[idx]
        if eqSonos.ip != sonos.ip {
            //Ip address changes
            sonosSystems.remove(at: idx)
            sonosSystems.insert(sonos, at: idx)
            sonos.active = eqSonos.active
        }
    }
    

    func showDemo() {
        self.stopDiscovery()
        
        let t1 = SonosDevice(roomName: "Bedroom_3", deviceName: "PLAY:3", url: URL(string:"http://192.168.178.91")!, ip: "192.168.178.91", udn: "some-udn-1", deviceInfo: SonosDeviceInfo(zoneName: "Bedroom_3+1", localUID: "01"), groupState: SonosGroupState(name: "Bedroom", groupID: "01", deviceIds: ["01", "02"]))
        t1.playState = .playing
        self.discoveredDevice(sonos: t1)
        
        let t2 = SonosDevice(roomName: "Bedroom_1", deviceName: "One", url: URL(string:"http://192.168.178.92")!, ip: "192.168.178.92", udn: "some-udn-2", deviceInfo:SonosDeviceInfo(zoneName: "Bedroom_3+1", localUID: "02"), groupState:  SonosGroupState(name: "Bedroom", groupID: "01", deviceIds: ["01", "02"]))
        t2.playState = .playing
        self.discoveredDevice(sonos: t2)
        
        let t3 = SonosDevice(roomName: "Kitchen", deviceName: "PLAY:1", url: URL(string:"http://192.168.178.93")!, ip: "192.168.178.93", udn: "some-udn-3",
                             deviceInfo: SonosDeviceInfo(zoneName: "Kitchen", localUID: "03"), groupState: SonosGroupState(name: "Kitchen", groupID: "03", deviceIds: ["03"]))
        t3.playState = .paused
        self.discoveredDevice(sonos: t3)
        
        let t4 = SonosDevice(roomName: "Living room", deviceName: "PLAY:5", url: URL(string:"http://192.168.178.94")!, ip: "192.168.178.94", udn: "some-udn-4",
                             deviceInfo: SonosDeviceInfo(zoneName: "Living room (RL)", localUID: "04"),
                             groupState: SonosGroupState(name: "Living room", groupID: "04", deviceIds: ["04", "05"]))
        t4.playState = .paused
        self.discoveredDevice(sonos: t4)
        
        let t5 = SonosDevice(roomName: "Living room", deviceName: "PLAY:5", url: URL(string:"http://192.168.178.95")!, ip: "192.168.178.95", udn: "some-udn-5",
                                 deviceInfo: SonosDeviceInfo(zoneName: "Living room (RR)", localUID: "05"),groupState: SonosGroupState(name: "", groupID: "", deviceIds: []))
        t5.playState = .paused
        self.discoveredDevice(sonos: t5)
        
        
        
//        let t6 = SonosDevice(roomName: "Living room", deviceName: "Playbase", url: URL(string:"http://192.168.178.94")!, ip: "192.168.178.94", udn: "some-udn-6",
//                             deviceInfo: SonosDeviceInfo(zoneName: "Living room", localUID: "06"),
//                             groupState: SonosGroupState())
//        t6.playState = .paused
//        self.discoveredDevice(sonos: t6)
        

    }
    
    public func createDebugReport() -> String {
        var sonosReport = "Sonos Debug Report - \(Date().description)"
        for sonos in unlistedSystems {
            sonosReport += "\n\n\n" + sonos.debugDescription
        }
        
        print(sonosReport)
        return sonosReport
    }
}

extension SonosController: SSDPDiscoveryDelegate {
    
    public func searchForDevices() {
        self.stopDiscovery()
        self.lastDiscoveryDeviceList.removeAll()
        self.unlistedSystems.removeAll()
        
        if (Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String) == "de.sn0wfreeze.Sonos-Volume-Control-Demo" {
            self.showDemo()
            return
        }
        
        dPrint("Searching devices")
        // Create the request for Sonos ZonePlayer devices
        let zonePlayerTarget = SSDPSearchTarget.deviceType(schema: SSDPSearchTarget.upnpOrgSchema, deviceType: "ZonePlayer", version: 1)
        let request = SSDPMSearchRequest(delegate: self, searchTarget: zonePlayerTarget)
        
        // Start a discovery session for the request and timeout after 10 seconds of searching.
        self.session = try! discovery.startDiscovery(request: request, timeout: 10.0)
    }
    
    func stopDiscovery() {
        self.session?.close()
        self.session = nil
    }
    
    public func discoveredDevice(response: SSDPMSearchResponse, session: SSDPDiscoverySession) {
                dPrint("Found device \(response.location)")
        retrieveDeviceInfo(response: response)
    }
    
    func retrieveDeviceInfo(response: SSDPMSearchResponse) {
        URLSession.init(configuration: URLSessionConfiguration.default).dataTask(with: response.location) { (data, resp, err) in
            if let data = data {
                let xml =  SWXMLHash.parse(data)
                let udn = xml["root"]["device"]["UDN"].element?.text
                //Check if device is already available
                if let sonos = self.sonosSystems.first(where: {$0.udn == udn}) {
                    //Update the device
                    sonos.update(withXML: xml, url: response.location)
                    sonos.updateAll {
                        self.discoveredDevice(sonos: sonos)
                    }
                }else {
                    //Add a new device
                    SonosDevice(xml: xml, url: response.location, { (sonos) in
                       self.discoveredDevice(sonos: sonos)
                    })
                }
            }
            }.resume()
    }
    
    
    /// A new SonosDevice has been discovered and initialized. Update the device list and groups
    ///
    /// - Parameter sonos: the newly discovered device
    func discoveredDevice(sonos: SonosDevice) {
        guard listOfUnallowedDevices.contains(sonos.modelName) == false else {return}
        self.unlistedSystems.insert(sonos)
        
        if sonos.groupState.isEmpty {
            //This is a paired device. Don't show these devices. But updated the paired count on others
            
            //Count the paired devices
            let pairedSpeaker = sonosSystems.first(where: {$0.roomName == sonos.roomName})
            let pairedSpeakersCount  = self.unlistedSystems.filter({$0.roomName == sonos.roomName && $0 != sonos}).count
            pairedSpeaker?.pairedSpeakers = pairedSpeakersCount
            
            //Update the view
            self.updatedSpeakers()
        }else if let sonos = self.sonosSystems.first(where: {$0 == sonos}) {
            // Device is already in the list of devices. Update the actual shown device
            
            self.lastDiscoveryDeviceList.append(sonos)
            self.updateGroups(sonos: sonos)
            
            //Count paired devices
            let pairedSpeakersCount  = self.unlistedSystems.filter({$0.roomName == sonos.roomName && $0 != sonos}).count
            if sonos.pairedSpeakers != pairedSpeakersCount {
                sonos.pairedSpeakers = pairedSpeakersCount
                self.updatedSpeakers()
            }
        }else {
            // This is a completely new device
            
            //Count paired devices
            let pairedSpeakersCount  = self.unlistedSystems.filter({$0.roomName == sonos.roomName && $0 != sonos}).count
            if sonos.pairedSpeakers != pairedSpeakersCount {
                sonos.pairedSpeakers = pairedSpeakersCount
                self.updatedSpeakers()
            }
            
            self.lastDiscoveryDeviceList.append(sonos)
            self.updateGroups(sonos: sonos)
            self.addDeviceToList(sonos: sonos)
        }
    }
    
    func sortSpeakers() {
        //Sort the sonos systems
        self.sonosSystems.sort { (lhs, rhs) -> Bool in
            return  lhs.readableName < rhs.readableName
        }
    }
    
    public func discoveredService(response: SSDPMSearchResponse, session: SSDPDiscoverySession) {
        dPrint("Found service \(response)")
    }
    
    public func closedSession(_ session: SSDPDiscoverySession) {
        dPrint("Session closed")
        self.removeOldDevices()
    }
}

let listOfUnallowedDevices = ["Sonos BOOST", "Sonos Bridge"]



