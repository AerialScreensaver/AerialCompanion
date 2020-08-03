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

    lazy var menuViewController = MenuViewController()
    
    // MARK: - Lifecycle
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        debugLog("Version \(Helpers.version) launched")

        // TODO detect launch params
        
        
        // Menu mode
        
        // Set the icon
        setIcon(mode: .normal)
        
        createMenu()
        
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


        menuViewController.setDelegate(self)
        // Grab the menu from the nib
        Bundle.main.loadNibNamed("MenuView", owner: menuViewController, topLevelObjects: &topLevelObjects)
        
        // This bugs me a lot, I shouldn't have to call this manually ?
        menuViewController.viewDidLoad()

        // Grab the menu from the nib and set it
        let objs = topLevelObjects! as [AnyObject]
        for obj in objs {
            if obj is NSMenu {
                // Menu found, set it on our statusItem !
                statusItem.menu = obj as? NSMenu
            }
        }
    }
}

