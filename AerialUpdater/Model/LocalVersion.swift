//
//  LocalVersion.swift
//  AerialUpdater
//
//  Created by Guillaume Louel on 25/07/2020.
//

import Foundation

struct LocalVersion {
    private static let aerialAllUsersPath: String = {
        let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent("Screen Savers/Aerial.saver") {
            let filePath = pathComponent.path
            print(filePath)

            return filePath
        } else {
            return ""
        }
    }()

    static let aerialPath: String = {
        let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        if let pathComponent = url.appendingPathComponent("Screen Savers/Aerial.saver") {
            let filePath = pathComponent.path
            print(filePath)

            return filePath
        } else {
            return ""
        }
    }()
    
    static func isInstalled() -> Bool {
        return FileManager.default.fileExists(atPath: aerialPath)
    }
    
    static func get() -> String {
        if !isInstalled() {
            return "Not installed"
        }
        
        let plistPath = aerialPath.appending("/Contents/Info.plist")

        if let output = Helpers.shell(launchPath: "/usr/bin/defaults", arguments: ["read","\(plistPath)","CFBundleShortVersionString"]) {
            return output.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return "Cannot read version number, please report"
        }
    }
    
}


