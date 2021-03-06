//
//  SonosTrackInfo.swift
//  Sonos_Volume_Control
//
//  Created by Alexander Heinrich on 30.03.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Foundation
import SWXMLHash

struct SonosTrackInfo {
    let title: String
    let album: String
    let artist: String
    let streamContent: String?
    var playMedium: String?
    
    public private(set) var containsErrors = false
    
    init(xml: XMLIndexer) {
        title = xml["dc:title"].element?.text ?? "Unknown Title"
        album = xml["upnp:album"].element?.text ?? "Unknown Album"
        artist = xml["dc:creator"].element?.text ?? "Unkown Artist"
        streamContent = xml["r:streamContent"].element?.text
        
        if title == "Unknown Title" || album == "Unknown Album" || artist == "Unkown Artist" {
            containsErrors = true
        }
    }
    
    func trackText() -> String {
        if containsErrors,
            let streamContent = self.streamContent {
            return streamContent
        }
        return "\(title) - \(artist)"
    }
    
    var description: String {
        return "\(title) - \(artist) - \(album) - \(streamContent ?? "No stream content")"
    }
}
