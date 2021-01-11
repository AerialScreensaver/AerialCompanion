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
    
    func windowWillClose(_ notification: Notification) {
        debugLog("windowWillClose")
        aerialWindowController.stopScreensaver()
    }
    
    func openSettings() {
        debugLog("open hosted settings")
        aerialWindowController.openPanel()
    }
}
