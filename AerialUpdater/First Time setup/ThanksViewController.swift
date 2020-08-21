//
//  ThanksViewController.swift
//  AerialUpdater
//
//  Created by Guillaume Louel on 16/08/2020.
//

import Cocoa

class ThanksViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func donateButton(_ sender: Any) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "https://www.paypal.me/glouel/")!
        workspace.open(url)
    }
}
