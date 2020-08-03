//
//  MenuViewController.swift
//  AerialUpdater
//
//  Created by Guillaume Louel on 03/08/2020.
//

import Cocoa

class MenuViewController: NSViewController, UpdateCallback {
    lazy var infoWindowController = InfoWindowController()
    lazy var updateCheckWindowController = UpdateCheckWindowController()

    // This is for the custom views on top
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
    

    // Settings
    @IBOutlet var menuLaunchAtStartup: NSMenuItem!
    @IBOutlet var menuLaunchInBackground: NSMenuItem!

    @IBOutlet var menuDebugMode: NSMenuItem!

    
    // The menu itself
    @IBOutlet var statusMenu: NSMenu!
    
    var appDelegate : AppDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Let's make sure our delegate is set
        Update.instance.setCallback(self)

        // Let's check right now the manifest status
        CachedManifest.instance.updateNow()

        updateMenuSettings()
        updateMenuContent()
        
        // Then set the callback
        //BackgroundCheck.instance.set()
    }
    
    func setDelegate(_ delegate: AppDelegate) {
        appDelegate = delegate
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
                
                // We may need to update AerialUpdater. This will be done as infrequently as possible, only in case of a security issue (not for features)
                if UpdaterVersion.needsUpdating() {
                    print(manifest.updaterVersion)
                    print(Helpers.version)
                    self.versionLabel.stringValue = "New AerialUpdater"
                    self.versionImageView.isHidden = true
                    self.versionInstallNow.isHidden = false
                    self.goodTrick.isHidden = true
                    return
                }
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
    
    
    // This is our callback for the update proper
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

    func setIcon(mode: IconMode) {
        appDelegate?.setIcon(mode: mode)
    }
    
    
    // MARK: - Custom UI Actions
    
    // Installation Button
    @IBAction func versionInstallNowClick(_ sender: Any) {
        if UpdaterVersion.needsUpdating() {
            let workspace = NSWorkspace.shared
            let url = URL(string: "https://github.com/glouel/AerialUpdater/releases")!
            workspace.open(url)
            return
        }
        
        versionInstallNow.isHidden = true
        versionLabel.stringValue = "Hold on..."

        // Start spinning
        goodTrick.isHidden = false
        goodTrick.startAnimation(self)
        
        // Launch the update
        Update.instance.perform(self)
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
        var topLevelObjects: NSArray? = NSArray()
        if !Bundle.main.loadNibNamed(NSNib.Name("UpdateCheckWindowController"),
                            owner: updateCheckWindowController,
                            topLevelObjects: &topLevelObjects) {
            errorLog("Could not load nib for InfoWindow, please report")
        }
        updateCheckWindowController.setCallback(self)
        updateCheckWindowController.windowDidLoad()
        updateCheckWindowController.showWindow(self)
        updateCheckWindowController.window!.makeKeyAndOrderFront(self)
        updateCheckWindowController.startCheck()
    }
    
    // MARK: - Settings
    
    /// Show About Updater version window
    @IBAction func aboutUpdater(_ sender: NSMenuItem) {
        var topLevelObjects: NSArray? = NSArray()
        if !Bundle.main.loadNibNamed(NSNib.Name("InfoWindowController"),
                            owner: infoWindowController,
                            topLevelObjects: &topLevelObjects) {
            errorLog("Could not load nib for InfoWindow, please report")
        }
        infoWindowController.windowDidLoad()
        infoWindowController.showWindow(self)
        infoWindowController.window!.makeKeyAndOrderFront(self)
    }
    
    @IBAction func launchAtStartup(_ sender: NSMenuItem) {
        Preferences.launchAtStartup = !Preferences.launchAtStartup
        
        sender.state = Preferences.launchAtStartup ? .on : .off
    }
    
    @IBAction func launchInBackground(_ sender: NSMenuItem) {
        Preferences.launchInBackground = !Preferences.launchInBackground
        
        sender.state = Preferences.launchInBackground ? .on : .off
    }
    
    @IBAction func debugMode(_ sender: Any) {
        Preferences.debugMode = !Preferences.debugMode
        
        menuDebugMode.state = Preferences.debugMode ? .on : .off
    }
    
    // Bye
    @IBAction func quitButton(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
}
