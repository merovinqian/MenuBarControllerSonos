//
//  VolumeSpeakerView.swift
//  Sonos_Volume_Control
//
//  Created by Alexander Heinrich on 12.08.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa
import SonoSwift

class VolumeSpeakerView: NSView {
    var speaker: SonosDevice!
    @IBOutlet var volumeButton: NSButton!
    @IBOutlet var volumeSlider: NSSlider!
    @IBOutlet weak var speakerName: NSTextField!
    
    private override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.viewSetup()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    static func withSpeaker(speaker: SonosDevice) -> VolumeSpeakerView {
        var topLevelObjects: NSArray?
        Bundle.main.loadNibNamed(NSNib.Name(rawValue: "VolumeSpeakerView"), owner: self, topLevelObjects: &topLevelObjects)
        
        let view =  topLevelObjects?.first(where: { $0 is VolumeSpeakerView } ) as? VolumeSpeakerView
        view?.speaker = speaker
        view?.update()
        return view!
    }
    
    
    /// Setup the vire for a volume speaker view
    func viewSetup() {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.volumeButton.setButtonType(.momentaryChange)
        self.volumeButton.target = self
        self.volumeButton.action = #selector(muteSpeaker)
        self.addSubview(self.volumeButton)
        self.addSubview(self.volumeSlider)
        self.addSubview(self.speakerName)
        
        //Volume Button
        self.volumeButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8.0).isActive = true
        self.volumeButton.centerYAnchor.constraint(equalTo: self.volumeSlider.centerYAnchor, constant: 0.0).isActive = true
        self.volumeButton.heightAnchor.constraint(equalToConstant: 20.0).isActive = true
        self.volumeButton.widthAnchor.constraint(equalToConstant: 20.0).isActive = true

        // Volume slider
        self.volumeSlider.minValue = 0.0
        self.volumeSlider.maxValue = 100.0
        self.volumeSlider.isVertical = false
        self.volumeSlider.leadingAnchor.constraint(equalTo: self.volumeButton.trailingAnchor, constant: 8.0).isActive = true
        self.volumeSlider.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -8.0).isActive = true
        self.volumeSlider.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -4.0).isActive = true
        
        self.volumeSlider.integerValue = self.speaker.currentVolume
        
        // Speaker Name Label
        
        self.speakerName.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 8.0).isActive = true
//        self.speakerName.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 8.0).isActive = true
        self.speakerName.topAnchor.constraint(equalTo: self.topAnchor, constant: 4.0).isActive = true
        self.speakerName.bottomAnchor.constraint(equalTo: self.volumeSlider.topAnchor, constant: -4.0).isActive = true
        
        self.heightAnchor.constraint(equalToConstant: 35.0)
        
        
        self.updateLayer()
    }
    
    
    /// Mute the speaker
    @IBAction func muteSpeaker(sender: NSButton) {
        if speaker.muted {
            speaker.setMute(muted: false)
        }else {
            speaker.setMute(muted: true)
        }
        self.updateMuteButton()
    }
    
    
    /// Update the volume button
    func updateMuteButton(){
        if speaker.muted {
            self.volumeButton.image = #imageLiteral(resourceName: "ic_volume_off")
        }else {
            self.volumeButton.image = #imageLiteral(resourceName: "ic_volume_up")
        }
    }
    
    
    /// Change the speakers volume
    ///
    /// - Parameter slider: NSSlider that has called the action
    @IBAction func changeVolume(slider: NSSlider) {
        self.speaker.setVolume(volume: slider.integerValue)
    }
    
    func update() {
        self.speaker.getVolume { (currentVolume) in
            self.volumeSlider.integerValue = currentVolume
        }
        
        self.speaker.updateMute()
        self.updateMuteButton()
        self.speakerName.stringValue = self.speaker.readableName
    }
    
}
