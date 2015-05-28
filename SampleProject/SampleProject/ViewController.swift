//
//  ViewController.swift
//  SampleProject
//
//  Created by Andreas Neusüß on 25.05.15.
//  Copyright (c) 2015 Cocoawah. All rights reserved.
//

import UIKit
class ViewController: UIViewController {

    let permissionController = PermissionController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func showPermissionButtonPressed(sender: AnyObject) {
        permissionController.presentPermissionViewIfNeededInViewController(self, interestedInPermission: .Location, successBlock: { () -> () in
            
            println("Location Access Granted. You could locate your user now.")
            
        }) { () -> () in
            
            println("Location Access Denied.")
        }
    }

}

