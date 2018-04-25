//
//  SonosGroupState.swift
//  Menu Bar Controller for Sonos
//
//  Created by Alexander Heinrich on 24.03.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa
import SWXMLHash

public struct SonosGroupState {
    public let name: String
    public let groupID: String
    public let deviceIds: [String]
    
    public init(xml: XMLIndexer) {
        let attributes = xml["s:Envelope"]["s:Body"]["u:GetZoneGroupAttributesResponse"]
        self.name = attributes["CurrentZoneGroupName"].element?.text ?? ""
        let gId = attributes["CurrentZoneGroupID"].element?.text ?? ""
        self.groupID = gId
        let deviceIdString = attributes["CurrentZonePlayerUUIDsInGroup"].element?.text ?? ""
        self.deviceIds =  deviceIdString.split(separator: ",").map({String($0)})
        
    }
    
    
    /// This creates an empty group state, which cannot be changed
    internal init() {
        name = ""
        groupID = ""
        deviceIds = []
    }
    
    internal var debugDescription: String {
        return """
        
        GROUP STATE:
        ---------------------
        Group name: \(name)
        Group id: \(groupID)
        device ids: \(deviceIds.joined(separator:","))
        """
    }
    
    var isEmpty: Bool {
        return groupID.isEmpty
    }
}
