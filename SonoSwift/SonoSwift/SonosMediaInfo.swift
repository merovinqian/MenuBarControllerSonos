//
//  SonosMediaInfo.swift
//  SonoSwift
//
//  Created by Alexander Heinrich on 08.08.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa
import SWXMLHash


/// This struct defines information received from the GetMediaInfoUrl. The information is mostly useful for Stations / Podcasts / Radio
public struct SonosMediaInfo {
    
    public var mediaTitle: String?
    public var currentURI: String?
    
    /// Normally not implemented
    private var stringMediaDuration: String?
    
    public init(xml: XMLIndexer) {
        
        self.currentURI = xml["currentURI"].element?.text
        if let metaDataText = xml["s:Envelope"]["s:Body"]["u:GetMediaInfoResponse"]["CurrentURIMetaData"].element?.text {
            let metadataXML = SWXMLHash.parse(metaDataText)
            self.mediaTitle = metadataXML["DIDL-Lite"]["item"]["dc:title"].element?.text
        }
    }
}
