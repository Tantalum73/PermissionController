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

    @IBAction func showPermissionButtonPressed(_ sender: AnyObject) {
        
        //Grab the initialized PermissionController object and call the method to start the presentation.
        //In this case I am interested in the location permission. In this case, when the user dismisses the dialog the successBlock is called if the user has given the permission. Otherwise, the failBlock will be executed.
        permissionController.presentPermissionViewIfNeededInViewController(self, interestedInPermission: .location, successBlock: { () -> () in
            
            print("Location Access Granted. You could locate your user now.")
            
        }) { () -> () in
            
            print("Location Access Denied.")
        }
    }

}

