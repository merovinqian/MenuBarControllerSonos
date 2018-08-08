//
//  MyApplication.swift
//  Menu Bar Controller for Sonos
//
//  Created by Alexander Heinrich on 25.07.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa
import IOKit

@objc(MyApplication)
class MyApplication: NSApplication {
    
@objc    override func sendEvent(_ event: NSEvent) {
        if (event.type == .systemDefined && event.subtype.rawValue == 8) {
            let keyCode = ((event.data1 & 0xFFFF0000) >> 16)
            let keyFlags = (event.data1 & 0x0000FFFF)
            // Get the key state. 0xA is KeyDown, OxB is KeyUp
            let keyState = (((keyFlags & 0xFF00) >> 8)) == 0xA
            let keyRepeat = (keyFlags & 0x1)
            mediaKeyEvent(key: Int32(keyCode), state: keyState, keyRepeat: keyRepeat > 0)
        }
        
        super.sendEvent(event)
    }
    
    
    
@objc    func mediaKeyEvent(key: Int32, state: Bool, keyRepeat: Bool) {
        // Only send events on KeyDown. Without this check, these events will happen twice
        if (state) {
            switch(key) {
            case NX_KEYTYPE_PLAY:
                // Do work
                
                SystemAudioRemoteHandler.shared.handlePlayPause()
                break
            case NX_KEYTYPE_FAST:
                // Do work
                SystemAudioRemoteHandler.shared.handleNext()
                break
            case NX_KEYTYPE_REWIND:
                // Do work
                SystemAudioRemoteHandler.shared.handlePrevious()
                break
            default:
                break
            }
        }
    }
}
