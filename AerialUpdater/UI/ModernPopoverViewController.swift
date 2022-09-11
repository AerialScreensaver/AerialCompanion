//
//  ModernPopoverViewController.swift
//  Aerial Companion
//
//  Created by Guillaume Louel on 06/02/2022.
//

import Cocoa

class ModernPopoverViewController: NSViewController, UpdateCallback {
    lazy var infoWindowController = InfoWindowController()
    lazy var settingsWindowController = SettingsWindowController()
    lazy var updateCheckWindowController = UpdateCheckWindowController()
    

    @IBOutlet var updateAvailableBox: NSBox!

    @IBOutlet var playbackControlBox: NSBox!
    //@IBOutlet var playbackTopConstraint: NSLayoutConstraint!

    @IBOutlet var screenSaverBox: NSBox!
    //@IBOutlet var screenSaverTopConstraint: NSLayoutConstraint!

    @IBOutlet var desktopAndMonitorView: NSView!
    @IBOutlet var desktopBackgroundBox: NSBox!
    //@IBOutlet var desktopBackgroundTopConstraint: NSLayoutConstraint!

    @IBOutlet var thisMonitorBox: NSBox!

    //@IBOutlet var thisMonitorTopConstraint: NSLayoutConstraint!

    
    @IBOutlet var helpView: NSView!
    //@IBOutlet var helpViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet var companionBox: NSBox!

    // Labels
    @IBOutlet var updateLabel: NSTextField!
    
    @IBOutlet var updateButton: NSButton!
    @IBOutlet var versionLabel: NSTextField!

    @IBOutlet var playbackLabel: NSTextField!
    
    enum PlaybackMode {
        case none, desktop, monitor
    }
    
    var currentMode:PlaybackMode = .none
    
    var appDelegate : AppDelegate?
    
    var hasUpdate = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
/*print("set notif")
        DistributedNotificationCenter.default.addObserver(self,
            selector: #selector(self.test2(_:)),
            name: nil, object: nil)


  */
        // Do view setup here.
        versionLabel.stringValue = Consts.productName + " " + Helpers.version
        
        // Let's make sure our delegate is set
        Update.instance.setCallback(self)

        // Let's check right now the manifest status
        CachedManifest.instance.updateNow()

        // Update the UI
        update()

        // This will start the update process
        updateMenuContent()

        // Then set the callback
        BackgroundCheck.instance.set()
    }
    
    func setDelegate(_ delegate: AppDelegate) {
        appDelegate = delegate
    }
    
    // Update protocol
    func update() {
        if hasUpdate {
            updateAvailableBox.isHidden = false
        } else {
            updateAvailableBox.isHidden = true
        }
        
        switch currentMode {
        case .none:
            playbackControlBox.isHidden = true
            desktopAndMonitorView.isHidden = false
        case .desktop:
            playbackControlBox.isHidden = false
            playbackLabel.stringValue = "Desktop background"
            
            desktopAndMonitorView.isHidden = true
        case .monitor:
            playbackControlBox.isHidden = false
            playbackLabel.stringValue = "This monitor only"

            desktopAndMonitorView.isHidden = true
        }
    }
    
    func updateProgress(string: String, done: Bool) {
        DispatchQueue.main.async {
            if done {
                self.updateLabel.stringValue = string
            } else {
                self.updateLabel.stringValue = string
            }
        }
    }
    
    func updateMenuContent() {
        debugLog("umc")
        DispatchQueue.main.async {
            /*
            // If we have fetched the versions, put them in the UI
            if let manifest = CachedManifest.instance.manifest {
                self.menuBeta.title = "Beta (\(manifest.betaVersion))"
                self.menuRelease.title = "Release (\(manifest.releaseVersion))"
                
                // We may need to update AerialUpdater. This will be done as infrequently as possible, only in case of a security issue (not for features)
                if UpdaterVersion.needsUpdating() {
                    self.setIcon(mode: .notification)
                    print(manifest.updaterVersion)
                    print(Helpers.version)
                    self.versionLabel.stringValue = "New updater version"
                    self.versionImageView.isHidden = true
                    self.versionInstallNow.isHidden = false
                    self.goodTrick.isHidden = true
                    return
                }
            }*/
            
            let (statusString, shouldInstall) = Update.instance.check()
            debugLog("\(statusString) \(shouldInstall)")
            
            //self.versionLabel.stringValue = statusString

            if shouldInstall {
                self.hasUpdate = true
                self.update()
                self.setIcon(mode: .notification)
               
            } else {
                self.hasUpdate = false
                self.update()
                self.setIcon(mode: .normal)
            }
            self.updateButton.isEnabled = true
        }
    }
    
    func setIcon(mode: IconMode) {
        appDelegate?.setIcon(mode: mode)
    }
    
    // Classic screen saver mode
    @IBAction func screenSaverLaunch(_ sender: Any) {
        // Seriously, this is a *private* API...
        if let libHandle = dlopen("/System/Library/PrivateFrameworks/login.framework/Versions/Current/login", RTLD_LAZY) {
            let sym = dlsym(libHandle, "SACScreenSaverStartNow")
            typealias myFunction = @convention(c) () -> Void
            let SACLockScreenImmediate = unsafeBitCast(sym, to: myFunction.self)
            SACLockScreenImmediate()
            dlclose(libHandle)
        }
    }
    
    @IBAction func screenSaverSettings(_ sender: Any) {
        if #available(macOS 13, *) {
            _ = Helpers.shell(launchPath: "/usr/bin/osascript", arguments: [
            "-e", "tell application \"System Settings\"",
            "-e","activate",
            "-e","end tell"])
        } else {
            _ = Helpers.shell(launchPath: "/usr/bin/osascript", arguments: [
            "-e", "tell application \"System Preferences\"",
            "-e","set the current pane to pane id \"com.apple.preference.desktopscreeneffect\"",
            "-e","reveal anchor \"ScreenSaverPref\" of pane id \"com.apple.preference.desktopscreeneffect\"",
            "-e","activate",
            "-e","end tell"])

        }
    }
    
    @IBAction func screenSaverCheckForUpdate(_ sender: Any) {
        var topLevelObjects: NSArray? = NSArray()
        if !Bundle.main.loadNibNamed(NSNib.Name("UpdateCheckWindowController"),
                            owner: updateCheckWindowController,
                            topLevelObjects: &topLevelObjects) {
            errorLog("Could not load nib for InfoWindow, please report")
        }
        updateCheckWindowController.setCallback(self)
        updateCheckWindowController.windowDidLoad()
        updateCheckWindowController.showWindow(self)
        updateCheckWindowController.window!.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        updateCheckWindowController.startCheck()
        
    }
    
    // Playback control
    @IBAction func playbackStop(_ sender: Any) {
        if currentMode == .desktop {
            DesktopLauncher.instance.toggleLauncher()
        } else {
            SaverLauncher.instance.stopScreensaver()
        }
        currentMode = .none
        update()
    }
    
    @IBAction func playbackPause(_ sender: Any) {
        if currentMode == .desktop {
            DesktopLauncher.instance.togglePause()
        } else {
            SaverLauncher.instance.togglePause()
        }
    }
    
    @IBAction func playbackSkip(_ sender: Any) {
        if currentMode == .desktop {
            DesktopLauncher.instance.nextVideo()
        } else {
            SaverLauncher.instance.nextVideo()
        }
    }
    
    @IBAction func playbackHide(_ sender: Any) {
        if currentMode == .desktop {
            DesktopLauncher.instance.skipAndHide()
        } else {
            SaverLauncher.instance.skipAndHide()
        }
    }
    
    @IBAction func playbackSettings(_ sender: Any) {
        SaverLauncher.instance.openSettings()
        update()
        appDelegate?.closePopover(sender: nil)
    }
    
    // Update button
    @IBAction func updateButtonClick(_ sender: NSButton) {
        if UpdaterVersion.needsUpdating() {
            let workspace = NSWorkspace.shared
            let url = URL(string: "https://github.com/glouel/AerialCompanion/releases")!
            workspace.open(url)
            return
        }
        
        updateLabel.stringValue = "Hold on..."
        updateButton.isEnabled = false
        // Start spinning
        //goodTrick.isHidden = false
        //goodTrick.startAnimation(self)
        
        // Launch the update
        Update.instance.perform(self)
    }
    
    // Desktop background mode
    @IBAction func destkopModePlay(_ sender: Any) {
        currentMode = .desktop
        DesktopLauncher.instance.toggleLauncher()
        update()
        appDelegate?.closePopover(sender: nil)
    }
    
    @IBAction func desktopModeSettings(_ sender: Any) {
        SaverLauncher.instance.openSettings()
        update()
        appDelegate?.closePopover(sender: nil)
    }
    
    //This monitor only mode
    @IBAction func thisMonitorPlay(_ sender: Any) {
        currentMode = .monitor
        SaverLauncher.instance.windowMode()
        update()
        appDelegate?.closePopover(sender: nil)
    }

    @IBAction func thisMonitorSettings(_ sender: Any) {
        SaverLauncher.instance.openSettings()
        update()
        appDelegate?.closePopover(sender: nil)
    }
    
    // Settings/Exit
    
    @IBAction func companionInfoClick(_ sender: Any) {
        var topLevelObjects: NSArray? = NSArray()
        if !Bundle.main.loadNibNamed(NSNib.Name("InfoWindowController"),
                            owner: infoWindowController,
                            topLevelObjects: &topLevelObjects) {
            errorLog("Could not load nib for InfoWindow, please report")
        }
        infoWindowController.windowDidLoad()
        infoWindowController.showWindow(self)
        infoWindowController.window!.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        appDelegate?.closePopover(sender: nil)
    }
    
    @IBAction func companionSettingsClick(_ sender: Any) {
        var topLevelObjects: NSArray? = NSArray()
        if !Bundle.main.loadNibNamed(NSNib.Name("SettingsWindowController"),
                            owner: settingsWindowController,
                            topLevelObjects: &topLevelObjects) {
            errorLog("Could not load nib for SettingsWindow, please report")
        }
        settingsWindowController.windowDidLoad()
        settingsWindowController.showWindow(self)
        settingsWindowController.window!.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        appDelegate?.closePopover(sender: nil)
    }
    
    @IBAction func helpClick(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://aerialscreensaver.github.io/support.html")!
        workspace.open(url)
        appDelegate?.closePopover(sender: nil)
    }
    
    @IBAction func exitClick(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
}
