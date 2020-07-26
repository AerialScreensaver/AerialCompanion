//
//  AppDelegate.swift
//  AerialUpdater
//
//  Created by Guillaume Louel on 24/07/2020.
//

import Cocoa

enum IconMode {
    case normal, updating, notification
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    // This is not particularly pretty, can't seem to manage to put the menu in a controller... !
    @IBOutlet var versionLabel: NSTextField!
    @IBOutlet var versionImageView: NSImageView!
    @IBOutlet var versionInstallNow: NSButton!
    
    @IBOutlet var goodTrick: NSProgressIndicator!
    
    // Menu entries
    // Desired version
    @IBOutlet var menuAlpha: NSMenuItem!
    @IBOutlet var menuBeta: NSMenuItem!
    @IBOutlet var menuRelease: NSMenuItem!
    
    // Update mode
    @IBOutlet var menuAutomatic: NSMenuItem!
    @IBOutlet var menuNotifyMe: NSMenuItem!
    
    // Check every
    @IBOutlet var menuHour: NSMenuItem!
    @IBOutlet var menuDay: NSMenuItem!
    @IBOutlet var menuWeek: NSMenuItem!
    
    @IBOutlet var menuDebugMode: NSMenuItem!

    // MARK: - Lifecycle
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        debugLog("Version \(Helpers.version) launched")
        // Let's make sure our delegate is set
        Update.instance.setAppDelegate(ad: self)

        // Let's check right now the manifest status
        CachedManifest.instance.updateNow()
        
        // Set the icon
        setIcon(mode: .normal)
        
        createMenu()
        
        // Then set the callback
        BackgroundCheck.instance.set()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    // Change the icon based on status
    func setIcon(mode: IconMode) {
        DispatchQueue.main.async {
            print("setIcon")
            switch mode {
            case .normal:
                self.statusItem.image = NSImage(named: "Status48")
            case .updating:
                self.statusItem.image = NSImage(named: "StatusTransp48")
            case .notification:
                self.statusItem.image = NSImage(named: "StatusGreen48")
            }

            self.statusItem.image?.size.width = 22
            self.statusItem.image?.size.height = 22
        }
    }
    
    // MARK: - Menu Content Setup and Update
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

    // This is only called once at startup
    func updateMenuSettings() {
        // Desired video format
        switch Preferences.desiredVersion {
        case .alpha:
            menuAlpha.state = .on
        case .beta:
            menuBeta.state = .on
        case .release:
            menuRelease.state = .on
        }
        
        switch Preferences.updateMode {
        case .automatic:
            menuAutomatic.state = .on
        case .notifyme:
            menuNotifyMe.state = .on
        }

        switch Preferences.checkEvery {
        case .hour:
            menuHour.state = .on
        case .day:
            menuDay.state = .on
        case .week:
            menuWeek.state = .on
        }
        
        menuDebugMode.state = Preferences.debugMode ? .on : .off
    }
    
    // This is called periodically to refresh the view
    func updateMenuContent() {
        DispatchQueue.main.async {
            // If we have fetched the versions, put them in the UI
            if let manifest = CachedManifest.instance.manifest {
                self.menuAlpha.title = "Alpha (\(manifest.alphaVersion))"
                self.menuBeta.title = "Beta (\(manifest.betaVersion))"
                self.menuRelease.title = "Release (\(manifest.releaseVersion))"
            }
            
            let (statusString, shouldInstall) = Update.instance.check()

            self.versionLabel.stringValue = statusString
            self.goodTrick.isHidden = true

            if shouldInstall {
                // Make the button visible
                self.versionImageView.isHidden = true
                self.versionInstallNow.isHidden = false
            } else {
                // Make the button visible
                self.versionImageView.isHidden = false
                self.versionInstallNow.isHidden = true
            }
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

    // MARK: - Custom UI Actions
    
    // Installation Button
    @IBAction func versionInstallNowClick(_ sender: Any) {
        versionInstallNow.isHidden = true
        versionLabel.stringValue = "Hold on..."
        // Start spinning
        goodTrick.isHidden = false
        goodTrick.startAnimation(self)
        
        // Launch the update
    
        Update.instance.perform(ad: self)
    }
    
    // MARK: - Menu callbacks
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
    
    @IBAction func updateModeChange(_ sender: NSMenuItem) {
        sender.state = .on
        if sender == menuAutomatic {
            menuNotifyMe.state = .off
            Preferences.updateMode = .automatic
        } else if sender == menuNotifyMe {
            menuAutomatic.state = .off
            Preferences.updateMode = .notifyme
        }
    }
    
    @IBAction func checkEveryChange(_ sender: NSMenuItem) {
        sender.state = .on
        if sender == menuHour {
            menuDay.state = .off
            menuWeek.state = .off
            Preferences.checkEvery = .hour
        } else if sender == menuDay {
            menuHour.state = .off
            menuWeek.state = .off
            Preferences.checkEvery = .day
        } else if sender == menuWeek {
            menuHour.state = .off
            menuDay.state = .off
            Preferences.checkEvery = .week
        }
    }

    @IBAction func checkNow(_ sender: NSMenuItem) {
        // Force a cache update
        CachedManifest.instance.updateNow()
        // Then the UI
        updateMenuContent()
    }
    
    @IBAction func debugMode(_ sender: Any) {
        Preferences.debugMode = !Preferences.debugMode
        
        menuDebugMode.state = Preferences.debugMode ? .on : .off
    }
    
    // Bye
    @IBAction func menuQuit(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
}

