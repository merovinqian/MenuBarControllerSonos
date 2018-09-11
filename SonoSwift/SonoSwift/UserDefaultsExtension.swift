//
//  UserDefaultsExtension.swift
//  Sonos_Volume_Control
//
//  Created by Alexander Heinrich on 02.04.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa

extension UserDefaults {
    
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
