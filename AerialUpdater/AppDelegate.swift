//
//  AppDelegate.swift
//  AerialUpdater
//
//  Created by Guillaume Louel on 24/07/2020.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    // This is not particularly pretty, can't seem to manage to put the menu in a controller... !
    @IBOutlet var versionLabel: NSTextField!
    
    @IBOutlet var versionImageView: NSImageView!
    @IBOutlet var versionInstallNow: NSButton!
    
    @IBOutlet var goodTrick: NSProgressIndicator!
    
    // Menu entries
    @IBOutlet var menuAlpha: NSMenuItem!
    @IBOutlet var menuBeta: NSMenuItem!
    @IBOutlet var menuRelease: NSMenuItem!
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Let's check right now the manifest status
        CachedManifest.instance.updateNow()
        
        // Set the icon
        statusItem.image = NSImage(named: "Status48")
        statusItem.image?.size.width = 22
        statusItem.image?.size.height = 22
        
        createMenu()
        errorLog("Version \(Helpers.version) launched")
    }

    // Load the menu from MenuView.xib and attach it to our StatusItem
    func createMenu() {
        var topLevelObjects: NSArray? = NSArray()

        // Grab the menu from the nib
        Bundle.main.loadNibNamed("MenuView", owner: self, topLevelObjects: &topLevelObjects)
        let objs = topLevelObjects! as [AnyObject]
        
        for obj in objs {
            if obj is NSMenu {
                // Menu found, set it on our statusItem !
                statusItem.menu = obj as? NSMenu
            }
        }

        updateMenuSettings()
        updateMenuContent()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // MARK: - Menu Content
    // This is only called once at startup
    func updateMenuSettings() {
        print("ums")
        // Desired video format
        switch Preferences.desiredVersion {
        case .alpha:
            menuAlpha.state = .on
        case .beta:
            menuBeta.state = .on
        case .release:
            menuRelease.state = .on
        }
    }
    
    // This is called periodically to refresh the view
    func updateMenuContent() {
        print("umc")

        // If we have fetched the versions, put them in the UI
        if let manifest = CachedManifest.instance.manifest {
            menuAlpha.title = "Alpha (\(manifest.alphaVersion))"
            menuBeta.title = "Beta (\(manifest.betaVersion))"
            menuRelease.title = "Release (\(manifest.releaseVersion))"
        }
        
        let (statusString, shouldInstall) = Update.check()

        versionLabel.stringValue = statusString
        goodTrick.isHidden = true

        if shouldInstall {
            // Make the button visible
            versionImageView.isHidden = true
            versionInstallNow.isHidden = false
        } else {
            // Make the button visible
            versionImageView.isHidden = false
            versionInstallNow.isHidden = true
        }
    }
    
    // This is our callback
    func updateProgress(string: String, done: Bool) {
        DispatchQueue.main.async {
            if done {
                self.goodTrick.stopAnimation(self)
                self.goodTrick.isHidden = true
                self.versionLabel.stringValue = string
                
                if string == "OK" {
                    self.updateMenuContent()
                }
            } else {
                self.versionLabel.stringValue = string
            }
        }
    }

    // MARK: UI Actions
    
    // Installation Button
    @IBAction func versionInstallNowClick(_ sender: Any) {
        versionInstallNow.isHidden = true
        versionLabel.stringValue = "Hold on..."
        // Start spinning
        goodTrick.isHidden = false
        goodTrick.startAnimation(self)
        
        // Launch the update
        Update.perform(ad: self)
    }
    
    @IBAction func desiredVersionChange(_ sender: NSMenuItem) {
        // There's probably a better way to do this...
        sender.state = .on
        if sender == menuAlpha {
            menuBeta.state = .off
            menuRelease.state = .off
            Preferences.desiredVersion = .alpha
        } else if sender == menuBeta {
            menuAlpha.state = .off
            menuRelease.state = .off
            Preferences.desiredVersion = .beta
        } else if sender == menuRelease {
            menuAlpha.state = .off
            menuBeta.state = .off
            Preferences.desiredVersion = .release
        }
        
        updateMenuContent()
    }
    
    // Bye
    @IBAction func menuQuit(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
}

