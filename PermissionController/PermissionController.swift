//
//  PermissionController.swift
//  ClubNews
//
//  Created by Andreas Neusüß on 28.04.15.
//  Copyright (c) 2015 Cocoawah. All rights reserved.
//

import UIKit
import MapKit
import EventKit
import UserNotifications
/**
Enum to express types of permission in that you are interested in.
 
 - Location:     Location permission
 - Calendar:     Calendar permission
 - Notification: Notification permission
 */
public enum PermissionInterestedIn {
    case location, calendar, notification
}

/// Exposes the interface for persenting the permission dialog and handles the actions.
open class PermissionController: NSObject, CLLocationManagerDelegate {
    fileprivate var locationManager : CLLocationManager?
    fileprivate var eventStore : EKEventStore?
    fileprivate var currentViewControllerView: UIView?
    
    fileprivate var calendarSuccessBlock : (()->())?
    fileprivate var calendarFailureBlock: (()->())?
    
    fileprivate var successBlock : (()->())?
    fileprivate var failureBlock: (()->())?


/**
Use this method to present the permission view.
The user will be asked to give permissions by a dialog.

When the user already granted a permission, the button is not enabled and a checkmark reflects it.
     
By specifying a `interestedInPermission` you register the completion and failure blocks to be executed when the user finfished the interaction with the dialog. If the operation you want to start depends on a permission, you can continue or cancel it in those blocks if you registered in that permission.

- returns: Bool that is true, when requested permission is already granted.
If other permissions are missing, the PermissionView will be displayed and false is returned.
    
- parameter viewController: The UIViewController on which the PermissionView shall be presented.
    
- parameter interestedInPermission: Indicates in which action the reuest is interested in. This value decides, whether the permission requesting was successful or not and therefore which completion block will be called. If you are only interested in the location permission to continue an operation, you can rely on the successBlock/failureBlock to be executed after the user was asked and continue or cancel the operation.
    
- parameter successBlock: This block will be executed on the main thread if the user dismissed the PermissionView and gave the desired permission.
    
- parameter failureBlock: This block will be executed on the main thread if the user dismissed the PermissionView and did not gave the desired permission.
*/
    
    open func presentPermissionViewIfNeededInViewController(_ viewController: UIViewController, interestedInPermission: PermissionInterestedIn?, successBlock: (()->())?, failureBlock: (()->())? ) -> Bool {
        
        let status = stateOfPermissions()
        
        let allPermissionsGranted = status.permissionLocationGranted && status.permissionCalendarGranted && status.permissionNotificationGranted
        
        self.successBlock = successBlock
        self.failureBlock = failureBlock
        
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
        
        if !allPermissionsGranted {
            //presenting
            let explanationViewController = ModalExplanationViewController()
            explanationViewController.permissionActionHandler = self
            explanationViewController.presentExplanationViewControllerOnViewController(viewController, nameOfNibs: ["PermissionView"], completion: { (_: Bool) -> () in
                
                if let interest = interestedInPermission {
                    let currentState = self.stateOfPermissions()
                    DispatchQueue.main.async(execute: {
                        
                        //TODO: maybe in the future: accept more than one desiredPermission
                        switch interest {
                        case .location :
                            if currentState.permissionLocationGranted {
                                successBlock?()
                            }
                            else {
                                failureBlock?()
                            }
                            break
                            
                        case .calendar:
                            if currentState.permissionCalendarGranted {
                                successBlock?()
                            }
                            else {
                                failureBlock?()
                            }
                            break
                            
                        case .notification:
                            if currentState.permissionNotificationGranted {
                                successBlock?()
                            }
                            else {
                                failureBlock?()
                            }
                            break
                            
                        }
                    })
                }
            })
            //return something so that the calling code an continue.
            return false
        }
                
        successBlock?()
        return true
    }
    
    
    //MARK: - CLLocationManagerDelegate
    
    /**
     Receives CLLocationManagerDelegate authorization calls and writes them to the `NSUserDefaults`. Then, a notification is posted that tells the displayed dialog to update the UI accordingly.
     */
    open func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        let defaults = UserDefaults.standard
        switch status {
        case .authorizedAlways:
            defaults.set(true, forKey: "LocationPermission")
            defaults.set(false, forKey: "LocationPermissionAskedOnce")
            break
        case .authorizedWhenInUse:
            defaults.set(false, forKey: "LocationPermission")
            defaults.set(false, forKey: "LocationPermissionAskedOnce")
            break
        case .denied:
            defaults.set(false, forKey: "LocationPermission")
            defaults.set(true, forKey: "LocationPermissionAskedOnce")
            break
        case .notDetermined:
            defaults.set(false, forKey: "LocationPermission")
            defaults.set(false, forKey: "LocationPermissionAskedOnce")
            break
        case .restricted:
            defaults.set(false, forKey: "LocationPermission")
            defaults.set(true, forKey: "LocationPermissionAskedOnce")
            break
        }
        
        defaults.synchronize()
        
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "LocalizationAuthorizationStatusChanged"), object: manager)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "AuthorizationStatusChanged"), object: nil)
    }

    /**
     Open the Settings.app on the users device because he already declined the permission and it needs to be changed from there.
     */
    fileprivate func sendUserToSettings() {
        let url = URL(string: UIApplicationOpenSettingsURLString)!
        
        if UIApplication.shared.canOpenURL(url) {
            
            UIApplication.shared.openURL(url)
        }

    }
}

extension PermissionController: PermissionAskingProtocol {
    func stateOfPermissions() -> StatusOfPermissions {
        var status = StatusOfPermissions()
        let defaults = UserDefaults.standard

        if defaults.bool(forKey: "LocationPermission") == true || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways {
            status.permissionLocationGranted = true
        }
        if UserDefaults.standard.bool(forKey: "CalendarPermission") == true || EKEventStore.authorizationStatus(for: EKEntityType.event) == EKAuthorizationStatus.authorized {
            status.permissionCalendarGranted = true
        }
        let registeredNotificationSettigns = UIApplication.shared.currentUserNotificationSettings
        
        if registeredNotificationSettigns?.types.rawValue != 0 || defaults.bool(forKey: "NotificationPermission") == true {
            //Some notifications are registered or already asked (probably both)
            
            status.permissionNotificationGranted = true
        }
        return status
    }
    func permissionButtonLocationPressed() {
        let status = CLLocationManager.authorizationStatus()
        let userWasAskedOnce = UserDefaults.standard.bool(forKey: "LocationPermissionAskedOnce")
        
        if userWasAskedOnce && status != CLAuthorizationStatus.authorizedAlways && status !=  CLAuthorizationStatus.authorizedWhenInUse {
            
            sendUserToSettings()
            return
        }
        
        self.locationManager?.requestAlwaysAuthorization()
    }
    func permissionButtonCalendarPressed() {
        let status = EKEventStore.authorizationStatus(for: EKEntityType.event)
        if status == EKAuthorizationStatus.denied {
            sendUserToSettings()
            return
        }
        
        UserDefaults.standard.set(true, forKey: "CalendarPermissionWasAskedOnce")
        
        self.eventStore = EKEventStore()
        
        let accessCompletionHandler : EKEventStoreRequestAccessCompletionHandler = {(granted:Bool , error: Error?) in
        let defaults = UserDefaults.standard
        
        
        
        if granted {
            defaults.set(true, forKey: "CalendarPermission")
        }
        else {
            
            defaults.set(false, forKey: "CalendarPermission")
        }
        defaults.synchronize()
        DispatchQueue.main.async(execute: {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "AuthorizationStatusChanged"), object: nil)
            })
        }
        
        self.eventStore?.requestAccess(to: .event, completion: accessCompletionHandler)



    }
    func permissionButtonNotificationPressed() {
        
        //        NSNotificationCenter.defaultCenter().postNotificationName("AuthorizationStatusChanged", object: nil)
        let defaults = UserDefaults.standard
        let registeredNotificationSettigns = UIApplication.shared.currentUserNotificationSettings
        
        if registeredNotificationSettigns?.types.rawValue == 0 && defaults.bool(forKey: "NotificationPermissionWasAskedOnce") == true {
            //Some notifications are registered or already asked (probably both)
            
            sendUserToSettings()
            return
        }
        
        defaults.set(true, forKey: "NotificationPermissionWasAskedOnce")
        
        //iOS 10 changed this a little
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.badge,.sound]) { (granted, error) in
                if(granted){
                    let defaults = UserDefaults.standard
                    defaults.set(true, forKey: "NotificationPermission")
                }
                DispatchQueue.main.async(execute: {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "AuthorizationStatusChanged"), object: nil)
                })
            }
        } else {
            let desiredNotificationSettigns = UIUserNotificationSettings(types: [UIUserNotificationType.alert, .badge, .sound] , categories: nil)
            
            UIApplication.shared.registerUserNotificationSettings(desiredNotificationSettigns)
        }
        
    }
}



extension UIColor {
    
    /**
    returns UIColor from given hex value.
    
    - parameter hex: the hex value to be converted to uicolor
    
    - parameter alpha: the alpha value of the color
    
    - returns: the UIColor corresponding to the given hex and alpha value
    
    */
    class func colorFromHex (_ hex: Int, alpha: Double = 1.0) -> UIColor {
        let red = Double((hex & 0xFF0000) >> 16) / 255.0
        let green = Double((hex & 0xFF00) >> 8) / 255.0
        let blue = Double((hex & 0xFF)) / 255.0
        let color: UIColor = UIColor( red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha:CGFloat(alpha) )
        return color
    }
    
    /**
    returns UIColor from rgb value.
    
    - parameter red: the r value
    
    - parameter green: the g value
    
    - parameter blue: the b value
    
    */
    class func colorFromRGB (_ red: Int, green: Int, blue: Int) -> UIColor {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        return self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    
    
}
