//
//  ViewController.swift
//  AccessControlKitty
//
//  Created by Zoe Smith on 23/1/19.
//  Copyright © 2019 Hot Beverage. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var instructions: NSTextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func openExtensions(_ sender: Any) {
        let url = URL(string: "x-apple.systempreferences:com.apple.preferences")!
        NSWorkspace.shared.open(url)
    }
}
