//
//  VersionChecker.swift
//  AerialUpdater
//
//  Created by Guillaume Louel on 24/07/2020.
//

import Foundation

struct VersionChecker {
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
    
    static func isAerialInstalled() -> Bool {
        return FileManager.default.fileExists(atPath: aerialPath)
    }
    
    static func getAerialVersion() -> String {
        if !isAerialInstalled() {
            return "Aerial is not installed"
        }
        
        let plistPath = aerialPath.appending("/Contents/Info.plist")

        if let output = shell(launchPath: "/usr/bin/defaults", arguments: ["read","\(plistPath)","CFBundleShortVersionString"]) {
            return output.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return "Cannot read version number, please report"
        }
    }
    
    static func getAerialCreationDate() -> Date? {
        if !isAerialInstalled() {
            return nil
        }

        let attributes = try! FileManager.default.attributesOfItem(atPath: aerialPath)
        let creationDate = attributes[.creationDate] as! Date
        
        print(creationDate)
        return creationDate
    }
    
    // mdls -name kMDItemVersion Aerial.saver
    
    // Launch a process through shell and capture/return output
    private static func shell(launchPath: String, arguments: [String] = []) -> String? {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        task.waitUntilExit()

        return output
    }

}
