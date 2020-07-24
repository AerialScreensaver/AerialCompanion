//
//  ViewController.swift
//  AerialUpdater
//
//  Created by Guillaume Louel on 24/07/2020.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet var currentlyInstalledLabel: NSTextField!
    @IBOutlet var latestAvailableLabel: NSTextField!
    @IBOutlet var installNowButton: NSButton!
    @IBOutlet var desiredVersionPopup: NSPopUpButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        currentlyInstalledLabel.stringValue = VersionChecker.getAerialVersion()

        latestAvailableLabel.stringValue = "Unknown"
        installNowButton.isEnabled = false
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func desiredVersionPopupChange(_ sender: NSPopUpButton) {
        switch sender.indexOfSelectedItem {
        case 0: // Alpha
            print("Alpha")
        case 1: // Beta
            print("Beta")
        default: // Release
            print("Release")
        }
    }
    
    @IBAction func installNowButtonClick(_ sender: Any) {
    }
}

