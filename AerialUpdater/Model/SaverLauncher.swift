//
//  SaverLauncher.swift
//  Aerial
//
//  Created by Guillaume Louel on 17/11/2020.
//

import Foundation
import ScreenSaver

class SaverLauncher : NSObject, NSWindowDelegate {
    static let instance: SaverLauncher = SaverLauncher()
    
    let aerialWindowController = AerialWindow()
    var uiController: CompanionPopoverViewController?
   
    lazy var hostedSettingsWindowController = HostedSettingsWindowController()
    
    func windowMode() {
        var topLevelObjects: NSArray? = NSArray()
        if !Bundle.main.loadNibNamed(NSNib.Name("AerialWindow"),
                            owner: aerialWindowController,
                            topLevelObjects: &topLevelObjects) {
            errorLog("Could not load nib for AerialWindow, please report")
        }
        
        aerialWindowController.windowDidLoad()
        aerialWindowController.showWindow(self)
        aerialWindowController.window!.delegate = self
        aerialWindowController.window!.toggleFullScreen(nil)
        aerialWindowController.window!.makeKeyAndOrderFront(nil)
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func setController(_ controller: CompanionPopoverViewController) {
        uiController = controller
    }
    func windowWillClose(_ notification: Notification) {
        debugLog("windowWillClose")
        aerialWindowController.stopScreensaver()
        uiController?.updatePlaybackMode(mode: .none)
    }
    
    func stopScreensaver() {
        aerialWindowController.stopScreensaver()
        aerialWindowController.close()
    }
    
    func openSettings() {
        debugLog("open hosted settings WN")
        let settings = aerialWindowController.openPanel()
        
        // Make sure to pass our main controller for callbacks
        hostedSettingsWindowController.setController(uiController!)

        // We need to monitor the settings window, we do it here
        settings.windowController = hostedSettingsWindowController
        settings.delegate = hostedSettingsWindowController
    }
    
    func togglePause() {
        debugLog("toggle pause")
        aerialWindowController.togglePause()
    }
    
    func nextVideo() {
        debugLog("next video")
        aerialWindowController.nextVideo()        
    }
    
    func skipAndHide() {
        debugLog("skip and hide")
        aerialWindowController.skipAndHide()
    }
}
