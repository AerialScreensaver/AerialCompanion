//
//  UpdateCheckWindowController.swift
//  AerialUpdater
//
//  Created by Guillaume Louel on 03/08/2020.
//

import Cocoa

class UpdateCheckWindowController: NSWindowController, UpdateCallback {

    @IBOutlet var largeGoodTrick: NSProgressIndicator!
    
    @IBOutlet var progressLabel: NSTextField!
    
    @IBOutlet var actionButton: NSButton!
    
    var menuCallback : MenuViewController?
    
    override func windowDidLoad() {
        super.windowDidLoad()

        largeGoodTrick.startAnimation(self)
        progressLabel.stringValue = "Hold on..."
        actionButton.isHidden = true
    }
    
    func setCallback(_ cb: MenuViewController) {
        menuCallback = cb
    }
    
    func startCheck() {
        largeGoodTrick.startAnimation(self)
        progressLabel.stringValue = "Looking for new version..."

        // Force a cache update
        CachedManifest.instance.updateNow()
        
        largeGoodTrick.stopAnimation(self)

        // Make sure we don't need to update, or redirect you there
        if UpdaterVersion.needsUpdating() {
            progressLabel.stringValue = "A new version of AerialUpdater is required"
            actionButton.title = "Show me"
            actionButton.isHidden = false
        } else {
            let (statusString, shouldInstall) = Update.instance.check()

            if shouldInstall {
                progressLabel.stringValue = "New version : \(statusString)"
                actionButton.title = "Install"
                actionButton.isHidden = false

            } else {
                progressLabel.stringValue = "No new version available"
                actionButton.title = "Close"
                actionButton.isHidden = false
            }
        }

        // Then the Menu UI
        menuCallback!.updateMenuContent()
    }
    
    @IBAction func actionButtonClick(_ sender: NSButton) {
        if UpdaterVersion.needsUpdating() {
            let workspace = NSWorkspace.shared
            let url = URL(string: "https://github.com/glouel/AerialUpdater/releases")!
            workspace.open(url)
            return
        } else if sender.title == "Close" || sender.title == "Show me" {
            close()
        }
        
        let (_, shouldInstall) = Update.instance.check()

        if shouldInstall {
            actionButton.title = "Close"
            actionButton.isHidden = true
            largeGoodTrick.startAnimation(self)
            Update.instance.perform(self)
        } else {
            close()
        }
    }
    
    
    func updateProgress(string: String, done: Bool) {
        DispatchQueue.main.async {
            self.progressLabel.stringValue = string
            self.actionButton.title = "Close"
            if done {
                self.largeGoodTrick.stopAnimation(self)
                if string == "OK" {
                    self.progressLabel.stringValue = "Update successfully completed"
                }
                self.actionButton.isHidden = false

            } else {
                self.actionButton.isHidden = true
            }
        }
    }
    
    func updateMenuContent() {
        if let callback = menuCallback {
            callback.updateMenuContent()
        }
    }
    
    func setIcon(mode: IconMode) {
        if let callback = menuCallback {
            callback.setIcon(mode: mode)
        }
     }
}
