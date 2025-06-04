//
//  ViewController.swift
//  AccessControlKitty
//
//  Created by Zoe Smith on 23/1/19.
//  Copyright © 2018-9 Zoë Smith. Distributed under the MIT License.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var instructions: NSTextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func openExtensions(_ sender: Any) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") else { return }
        NSWorkspace.shared.open(url)
    }
    
    
}
