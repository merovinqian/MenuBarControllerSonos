//
//  AddManuallyController.swift
//  Sonos_Volume_Control
//
//  Created by Alexander Heinrich on 31.08.18.
//  Copyright © 2018 Sn0wfreeze Development UG. All rights reserved.
//

import Cocoa
import SonoSwift

class AddManuallyController: NSViewController {
    @IBOutlet weak var headerLabel: NSTextField!
    @IBOutlet weak var ipTextField: NSTextField!
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var explanationLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the texts
        headerLabel.stringValue = NSLocalizedString("Enter a valid IP Address from one of your speakers", comment: "Header Label of the view")
        addButton.title = NSLocalizedString("Add speaker", comment: "Button label")
        explanationLabel.stringValue = NSLocalizedString("To view the speakers IP Address: \nOpen the Sonos Controller App on your Mac.\nIn the Menu select: Sonos-> About my Sonos System", comment:"Explanation text")
    }
    
    
    /// The speaker will be added manually
    ///
    /// - Parameter sender: Sender Button
    @IBAction func addSpeaker(_ sender: Any) {
        let ipAddress = ipTextField.stringValue
        do {
            try SonosController.shared.addSpeakerManually(ipAddress: ipAddress, completion: { err in
                if let err = err {
                    dPrint(err)
                    
                    // An error occurred
                    let alert = NSAlert.init()
                    alert.addButton(withTitle: "OK")
                    
                    alert.messageText = NSLocalizedString("Could not connect to the speaker" , comment: "Error message")
                    alert.informativeText = NSLocalizedString("Check the following things:\nIs the IP Address correct?\nDoes your firewall block connections?", comment: "Error informative text")
                    alert.alertStyle = .warning
                    alert.runModal()
                }else {
                    let alert = NSAlert.init()
                    alert.addButton(withTitle: "OK")
                    
                    alert.messageText = NSLocalizedString("Successfully added speaker" , comment: "Success message")
                    alert.alertStyle = .warning
                    alert.runModal()
                }
            })
        }catch let error {
            dPrint(error)
            
            
            let alert = NSAlert.init()
            alert.addButton(withTitle: "OK")
            
            alert.messageText = NSLocalizedString("IP Address has been entered wrong. Check the IP Address again" , comment: "Error message")
            alert.alertStyle = .warning
            alert.runModal()
            
        }
    }
    
}
