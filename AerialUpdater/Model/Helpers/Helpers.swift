//
//  Helpers.swift
//  AerialUpdater
//
//  Created by Guillaume Louel on 25/07/2020.
//

import Foundation

struct Helpers {
    static var version: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    
    static var supportPath: String {
        // Grab an array of Application Support paths
        let appSupportPaths = NSSearchPathForDirectoriesInDomains(
            .applicationSupportDirectory,
            .userDomainMask,
            true)

        if appSupportPaths.isEmpty {
            errorLog("FATAL : app support does not exist!")
            fatalError()
        }

        let appSupportDirectory = (appSupportPaths[0] as String).appending("/AerialUpdater")

        if FileManager.default.fileExists(atPath: appSupportDirectory) {
            return appSupportDirectory
        } else {
            debugLog("Creating app support directory...")

            let fileManager = FileManager.default
            do {
                try fileManager.createDirectory(atPath: appSupportDirectory,
                                                withIntermediateDirectories: false, attributes: nil)
                return appSupportDirectory
            } catch let error {
                errorLog("FATAL : Couldn't create app support directory in User directory: \(error)")
                fatalError()
            }
        }
    }

    
    // Launch a process through shell and capture/return output
    static func shell(launchPath: String, arguments: [String] = []) -> String? {
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
