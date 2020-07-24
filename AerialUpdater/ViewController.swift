//
//  ViewController.swift
//  AerialUpdater
//
//  Created by Guillaume Louel on 24/07/2020.
//

import Cocoa

enum DesiredType: Int {
    case alpha, beta, release
}
class ViewController: NSViewController {
    var manifest: Manifest?
    var desiredVersion: DesiredType = .release
    @IBOutlet var currentlyInstalledLabel: NSTextField!
    @IBOutlet var latestAvailableLabel: NSTextField!
    @IBOutlet var installNowButton: NSButton!
    @IBOutlet var desiredVersionPopup: NSPopUpButton!
    
    @IBOutlet var spinner: NSProgressIndicator!
    @IBOutlet var progressLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        manifest = VersionChecker.getManifest()

        currentlyInstalledLabel.stringValue = VersionChecker.getAerialVersion()
        desiredVersionPopup.selectItem(at: desiredVersion.rawValue)
        installNowButton.isEnabled = false

        spinner.isHidden = true
        progressLabel.isHidden = true
        
        updateVersionLabel()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func desiredVersionPopupChange(_ sender: NSPopUpButton) {
        currentlyInstalledLabel.stringValue = VersionChecker.getAerialVersion()

        switch sender.indexOfSelectedItem {
        case 0: // Alpha
            desiredVersion = .alpha
        case 1: // Beta
            desiredVersion = .beta
        default: // Release
            desiredVersion = .release
        }
        
        updateVersionLabel()
    }
    
    func updateVersionLabel() {
        switch desiredVersion {
        case .alpha:
            if let manifest = manifest {
                latestAvailableLabel.stringValue = manifest.alphaVersion
            }
        case .beta:
            if let manifest = manifest {
                latestAvailableLabel.stringValue = manifest.betaVersion
            }
        case .release:
            if let manifest = manifest {
                latestAvailableLabel.stringValue = manifest.releaseVersion
            }
        }
        
        if (latestAvailableLabel.stringValue != currentlyInstalledLabel.stringValue) {
            installNowButton.isEnabled = true
        } else {
            installNowButton.isEnabled = false
        }
    }
    
    @IBAction func installNowButtonClick(_ sender: Any) {
        if let manifest = manifest {
            installNowButton.isEnabled = false
            spinner.isHidden = false
            spinner.startAnimation(self)
            progressLabel.isHidden = false

            VersionChecker.updateTo(desired: desiredVersion, manifest: manifest, vc: self)
        }
    }
    
    func updateProgress(string: String, done: Bool) {
        DispatchQueue.main.async {
            if done {
                self.progressLabel.stringValue = string
                self.spinner.stopAnimation(self)
                self.spinner.isHidden = true
                
                self.currentlyInstalledLabel.stringValue = VersionChecker.getAerialVersion()
            } else {
                self.progressLabel.stringValue = string
            }
        }
    }
    
}

