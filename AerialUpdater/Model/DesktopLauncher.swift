//
//  DesktopLauncher.swift
//  Aerial Companion
//
//  Created by Guillaume Louel on 02/12/2020.
//

import Foundation

class DesktopLauncher : NSObject, NSWindowDelegate {
    static let instance: DesktopLauncher = DesktopLauncher()
    
    
    let aerialDesktopController = AerialDesktop()
    var isRunning = false

    
    func toggleLauncher() {
        if !isRunning {
            var topLevelObjects: NSArray? = NSArray()
            if !Bundle.main.loadNibNamed(NSNib.Name("AerialDesktop"),
                                owner: aerialDesktopController,
                                topLevelObjects: &topLevelObjects) {
                errorLog("Could not load nib for AerialDesktop, please report")
            }
            
            aerialDesktopController.windowDidLoad()
            aerialDesktopController.showWindow(self)
            aerialDesktopController.window!.delegate = self
            aerialDesktopController.window!.toggleFullScreen(nil)
            aerialDesktopController.window!.makeKeyAndOrderFront(nil)
            
            NSApp.activate(ignoringOtherApps: true)
            
            isRunning = true
        } else {
            aerialDesktopController.window!.close()
            isRunning = false
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        debugLog("windowWillClose")
        aerialDesktopController.stopScreensaver()
    }
    
    func openSettings() {
        debugLog("open hosted settings")
        aerialDesktopController.openPanel()
    }
}
