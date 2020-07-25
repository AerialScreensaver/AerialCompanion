//
//  CachedManifest.swift
//  AerialUpdater
//
//  Created by Guillaume Louel on 25/07/2020.
//

import Foundation

class CachedManifest {
    static let instance: CachedManifest = CachedManifest()

    var manifest: Manifest?
    
    func updateNow() {
        do {
            let tManifest = try Manifest(fromURL: URL(string: "https://raw.githubusercontent.com/glouel/AerialUpdater/main/manifest.json")!)
            // All good ? Save
            manifest = tManifest
        } catch {
            //
        }
    }
}
