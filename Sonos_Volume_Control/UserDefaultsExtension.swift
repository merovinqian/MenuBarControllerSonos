//
//  UserDefaultsExtension.swift
//  Sonos_Volume_Control
//
//  Created by Alexander Heinrich on 02.04.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa

extension UserDefaults {
    var isLaunchAtLoginEnabled: Bool {
        get {
            return self.bool(forKey: "launchAtLogin")
        }
        set (v) {
            self.set(v, forKey: "launchAtLogin")
            self.synchronize()
        }
    }
    
    var activeSpeakerUDNs: [String]? {
        get {
            return self.array(forKey: "activeSpeakerUDNs") as? [String]
        }
        set(v) {
            self.set(v, forKey: "activeSpeakerUDNs")
            self.synchronize()
        }
    }
    
    /// Get the last active group id 
    var activeGroupId: String? {
        get {
            return self.string(forKey: "activeGroupId")
        }
        set(v) {
            self.set(v, forKey: "activeGroupId")
            self.synchronize()
        }
    }
    
    var manuallyAddedSpeakers: [String]? {
        get {
            return self.array(forKey: "manualSpeakers") as? [String]
        }
        set(v) {
            self.set(v, forKey: "manualSpeakers")
            self.synchronize()
        }
    }
}
