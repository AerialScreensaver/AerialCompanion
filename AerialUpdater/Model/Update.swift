//
//  Update.swift
//  AerialUpdater
//
//  Created by Guillaume Louel on 25/07/2020.
//

import Foundation

// Again this is a bit messy...
struct Update {
    
    // What should we do, is there a new version available ?
    static func check() -> (String, Bool) {
        if !LocalVersion.isInstalled() {
            return ("Not installed!", true)
        }

        if let manifest = CachedManifest.instance.manifest {
            let localVersion = LocalVersion.get()
            
            debugLog("local \(localVersion), alpha \(manifest.alphaVersion), beta \(manifest.betaVersion), release \(manifest.releaseVersion)")
            
            switch Preferences.desiredVersion {
            case .alpha:
                if localVersion == manifest.alphaVersion {
                    return ("\(localVersion) is installed", false)
                } else {
                    return ("\(manifest.alphaVersion) is available", true)
                }
            case .beta:
                if localVersion == manifest.betaVersion {
                    return ("\(localVersion) is installed", false)
                } else {
                    return ("\(manifest.betaVersion) is available", true)
                }
            case .release:
                if localVersion == manifest.releaseVersion {
                    return ("\(localVersion) is installed", false)
                } else {
                    return ("\(manifest.releaseVersion) is available", true)
                }
            }
        } else {
            return ("No network connection", false)
        }
    }
    
    static func perform(ad: AppDelegate) {
        guard let manifest = CachedManifest.instance.manifest else {
            errorLog("Trying to perform update with no manifest, please report")
            ad.updateProgress(string: "Error: No manifest", done: true)
            return
        }
        
        debugLog("Performing update")
        
        let supportUrl = URL(fileURLWithPath: Helpers.supportPath)

        let destinationUrl = supportUrl.appendingPathComponent("Aerial.saver.zip")
        let destinationSaverUrl = supportUrl.appendingPathComponent("Aerial.saver")

        // Make sure to delete a zip if exists
        if FileManager().fileExists(atPath: destinationUrl.path)
        {
            do {
                debugLog("Deleting old file from AppSupport")
                try FileManager().removeItem(at: destinationUrl)
            } catch {
                // ERROR
                errorLog("Cannot delete zip in AppSupport")
                ad.updateProgress(string: "Cannot delete zip in AppSupport", done: true)
                return
            }
        }

        if FileManager().fileExists(atPath: destinationSaverUrl.path)
        {
            do {
                debugLog("Deleting old saver file from AppSupport")
                try FileManager().removeItem(at: destinationSaverUrl)
            } catch {
                // ERROR
                errorLog("Cannot delete Aerial.saver in AppSupport")
                ad.updateProgress(string: "Cannot delete Aerial.saver in AppSupport", done: true)
                return
            }
        }

        var zipPath: String = ""

        switch Preferences.desiredVersion {
        case .alpha:
            zipPath = "https://github.com/glouel/Aerial/releases/download/v\(manifest.alphaVersion)/Aerial.saver.zip"
        case .beta:
            zipPath = "https://github.com/JohnCoates/Aerial/releases/download/v\(manifest.betaVersion)/Aerial.saver.zip"
        case .release:
            zipPath = "https://github.com/JohnCoates/Aerial/releases/download/v\(manifest.releaseVersion)/Aerial.saver.zip"
        }
        debugLog("Downloading...")
        ad.updateProgress(string: "Downloading...", done: false)
        
        FileDownloader.loadFileAsync(url: URL(string:zipPath)!) { (path, error) in
            if let perror = error {
                errorLog("Download error: \(perror.localizedDescription)")
                ad.updateProgress(string: "Error: \(perror.localizedDescription)", done: true)
            } else {
                verifyFile(path: path!, manifest: manifest, ad: ad)
            }
        }
    }
    
    // MARK: - Private helpers
    private static func verifyFile(path: String, manifest: Manifest, ad: AppDelegate) {
        debugLog("Verifying...")
        ad.updateProgress(string: "Verifying...", done: false)
        
        if FileManager.default.fileExists(atPath: path) {
            let dlsha = getZipSHA256(path: path)
            var tsha: String
            
            switch Preferences.desiredVersion {
            case .alpha:
                tsha = manifest.alphaSHA256
            case .beta:
                tsha = manifest.betaSHA256
            case .release:
                tsha = manifest.releaseSHA256
            }

            if tsha == dlsha {
                debugLog("Unzipping...")
                ad.updateProgress(string: "Unzipping...", done: false)

                _ = Helpers.shell(launchPath: "/usr/bin/unzip", arguments: ["-d", String(path[...path.lastIndex(of: "/")!]), path])
                
                var saverPath = path
                saverPath.removeLast(4)
                debugLog("Verifying signature...")
                ad.updateProgress(string: "Verifying signature...", done: false)

                if FileManager.default.fileExists(atPath: saverPath) {
                    let result = Helpers.shell(launchPath: "/usr/bin/codesign", arguments: ["-v", "-d", saverPath])
                    
                    if checkCodesign(result) {
                        if install(saverPath, ad: ad) {
                            // Pfew...
                            debugLog("Installed !")
                            ad.updateProgress(string: "OK", done: true)
                        } else {
                            errorLog("Cannot copy .saver")
                            ad.updateProgress(string: "Cannot copy .saver", done: true)

                        }
                        
                    } else {
                        errorLog("Codesigning verification failed")
                        ad.updateProgress(string: "Codesigning verification failed", done: true)
                    }
                } else {
                    errorLog("Aerial.saver not found in zip")
                    ad.updateProgress(string: "Aerial.saver not found in zip", done: true)
                }
            } else {
                errorLog("Downloaded file is corrupted")
                ad.updateProgress(string: "Downloaded file is corrupted", done: true)
            }
        } else {
            errorLog("Downloaded file not found")
            ad.updateProgress(string: "Downloaded file not found", done: true)
        }
        
    }

    private static func checkCodesign(_ result: String?) -> Bool {
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
    
    private static func install(_ path: String, ad: AppDelegate) -> Bool {
        if FileManager.default.fileExists(atPath: LocalVersion.aerialPath) {
            debugLog("Removing old version...")
            ad.updateProgress(string: "Removing old version...", done: false)
            if FileManager().fileExists(atPath: LocalVersion.aerialPath)
            {
                do {
                    try FileManager().removeItem(at: URL(fileURLWithPath: LocalVersion.aerialPath))
                } catch {
                    // ERROR
                    errorLog("Cannot delete zip in downloads directory")
                    ad.updateProgress(string: "Cannot delete zip in downloads directory", done: true)
                    return false
                }
            }
        }
        debugLog("Installing...")
        ad.updateProgress(string: "Installing...", done: false)

        do {
            try FileManager.default.moveItem(atPath: path, toPath: LocalVersion.aerialPath)
            return true
            
        } catch {
            return false
        }
        
    }
    
    private static func getZipSHA256(path: String) -> String {
        if FileManager.default.fileExists(atPath: path) {
            return String(Helpers.shell(launchPath: "/usr/bin/shasum",arguments: ["-a","256",path])!.split(separator: " ")[0])
        }
        return ""
    }
    
}
