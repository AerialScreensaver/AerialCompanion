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

    static func getManifest() -> Manifest? {
        do {
            let manifest = try Manifest(fromURL: URL(string: "https://raw.githubusercontent.com/glouel/AerialUpdater/main/manifest.json")!)
            return manifest
        } catch {
            //
            return nil
        }
    }
    
    static func updateTo(desired: DesiredType, manifest: Manifest, vc: ViewController) {
        // Make sure to delete a zip if exists
        let documentsUrl = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!

        let destinationUrl = documentsUrl.appendingPathComponent("Aerial.saver.zip")
        let destinationSaverUrl = documentsUrl.appendingPathComponent("Aerial.saver")

        if FileManager().fileExists(atPath: destinationUrl.path)
        {
            do {
                print("Deleting old file from Downloads")
                try FileManager().removeItem(at: destinationUrl)
            } catch {
                // ERROR
                vc.updateProgress(string: "Cannot delete zip in downloads directory", done: true)
                return
            }
        }

        if FileManager().fileExists(atPath: destinationSaverUrl.path)
        {
            do {
                print("Deleting old saver file from Downloads")
                try FileManager().removeItem(at: destinationSaverUrl)
            } catch {
                // ERROR
                vc.updateProgress(string: "Cannot delete Aerial.saver in downloads directory", done: true)
                return
            }
        }

        var zipPath: String = ""

        switch desired {
        case .alpha:
            zipPath = "https://github.com/glouel/Aerial/releases/download/v\(manifest.alphaVersion)/Aerial.saver.zip"
        case .beta:
            zipPath = "https://github.com/JohnCoates/Aerial/releases/download/v\(manifest.betaVersion)/Aerial.saver.zip"
        case .release:
            zipPath = "https://github.com/JohnCoates/Aerial/releases/download/v\(manifest.releaseVersion)/Aerial.saver.zip"
        }
        vc.updateProgress(string: "Downloading...", done: false)
        
        FileDownloader.loadFileAsync(url: URL(string:zipPath)!) { (path, error) in
            if let perror = error {
                vc.updateProgress(string: "Error: \(perror.localizedDescription)", done: true)
            } else {
                verifyFile(path: path!, desired: desired, manifest: manifest, vc: vc)
            }
        }
    }
    
    static func verifyFile(path: String, desired: DesiredType, manifest: Manifest, vc: ViewController) {
        vc.updateProgress(string: "Veryfing...", done: false)
        
        if FileManager.default.fileExists(atPath: path) {
            let dlsha = getZipSHA256(path: path)
            var tsha: String
            
            switch desired {
            case .alpha:
                tsha = manifest.alphaSHA256
            case .beta:
                tsha = manifest.betaSHA256
            case .release:
                tsha = manifest.releaseSHA256
            }

            if tsha == dlsha {
                vc.updateProgress(string: "Unzipping...", done: false)

                _ = shell(launchPath: "/usr/bin/unzip", arguments: ["-d", String(path[...path.lastIndex(of: "/")!]), path])
                
                var saverPath = path
                saverPath.removeLast(4)
                vc.updateProgress(string: "Verifying signature...", done: false)

                if FileManager.default.fileExists(atPath: saverPath) {
                    let result = shell(launchPath: "/usr/bin/codesign", arguments: ["-v", "-d", saverPath])
                    
                    if checkCodesign(result) {
                        if install(saverPath, vc: vc) {
                            // Pfew...
                            vc.updateProgress(string: "Installed !", done: true)
                        } else {
                            vc.updateProgress(string: "Cannot copy .saver", done: true)

                        }
                        
                    } else {
                        vc.updateProgress(string: "Codesigning verification failed", done: true)
                    }
                } else {
                    vc.updateProgress(string: "Aerial.saver not found in zip", done: true)
                }
            } else {
                vc.updateProgress(string: "Downloaded file is corrupted", done: true)
            }
        } else {
            vc.updateProgress(string: "Downloaded file not found", done: true)
        }
        
    }

    static func checkCodesign(_ result: String?) -> Bool {
        if let presult = result {
            let lines = presult.split(separator: "\n")
            
            var bundleVer = false
            var devIDVer = false
            
            for line in lines {
                print(line)
                if line.starts(with: "Identifier=com.JohnCoates.Aerial") {
                    bundleVer = true
                }
                if line.starts(with: "TeamIdentifier=3L54M5L5KK") {
                    devIDVer = true
                }
            }
            
            if bundleVer && devIDVer {
                return true
            } else {
                return false
            }

        } else {
            return false
        }
    }
    
    static func install(_ path: String, vc: ViewController) -> Bool {
        if FileManager.default.fileExists(atPath: aerialPath) {
            vc.updateProgress(string: "Removing old version...", done: false)
            if FileManager().fileExists(atPath: aerialPath)
            {
                do {
                    try FileManager().removeItem(at: URL(fileURLWithPath: aerialPath))
                } catch {
                    // ERROR
                    vc.updateProgress(string: "Cannot delete zip in downloads directory", done: true)
                    return false
                }
            }
        }
        vc.updateProgress(string: "Installing...", done: false)

        do {
            try FileManager.default.moveItem(atPath: path, toPath: aerialPath)
            return true
            
        } catch {
            return false
        }
        
    }
    
    static func getZipSHA256(path: String) -> String {
        if FileManager.default.fileExists(atPath: path) {
            return String(shell(launchPath: "/usr/bin/shasum",arguments: ["-a","256",path])!.split(separator: " ")[0])
        }
        return ""
    }
}
