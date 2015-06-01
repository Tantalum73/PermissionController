//
//  PermissionView.swift
//  ClubNews
//
//  Created by Andreas Neusüß on 16.05.15.
//  Copyright (c) 2015 Cocoawah. All rights reserved.
//

import UIKit

class PermissionView: UIView {
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var locationButton: UIButton!

    @IBOutlet weak var calendarButton: UIButton!
    
    @IBOutlet weak var notificationButton: UIButton!
    
    @IBOutlet weak var locationCheckmark: UIImageView!
    @IBOutlet weak var calendarChackmark: UIImageView!
    
    @IBOutlet weak var notificationCheckmark: UIImageView!
    
    ///The header of the view.
    ///You should describe why the app needs to have the permissions.
    @IBOutlet weak var headerLabel: UILabel!
    /**
    This label holds information about why the user should give the app access to his location.
    Also include the 'NSLocationAlwaysUsageDescription' key in your info.plist
    */
    @IBOutlet weak var locationDescriptionLabel: UILabel!
    /**
    This label holds information about why the user should give the app access to his calendar.
    Also include the 'NSCalendarsUsageDescription' key in your info.plist
    */
    @IBOutlet weak var calendarDescriptionLabel: UILabel!
    /**
    This label holds information about why the user should give the app access to send him notifications.
    Yet, only local notifications are supported but you can easily changed the requested permission to remote notifications.
    Also check the AppDelegate to see what is neccessary to update the permission state.
    */
    @IBOutlet weak var notificationDescriptionLabel: UILabel!

    
    private let colorForCheckedButtons = UIColor.colorFromHex(0x209922, alpha: 1)
    private var latestPermissionConfiguration : StatusOfPermissions?
    
    override func awakeFromNib() {
        setUpView()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        
        locationButton.imageEdgeInsets = imageInsetsForButton(locationButton)
        locationButton.titleEdgeInsets.left = -locationButton.imageView!.frame.width / 2
        
        
        calendarButton.imageEdgeInsets = imageInsetsForButton(calendarButton)
        calendarButton.titleEdgeInsets.left = -calendarButton.imageView!.frame.width / 2
        
        
        notificationButton.imageEdgeInsets = imageInsetsForButton(notificationButton)
        notificationButton.titleEdgeInsets.left = -notificationButton.imageView!.frame.width / 2
        
        tintButtonsBasedOnLatestPermissionStatus()
    }
    
    override func alignmentRectForFrame(frame: CGRect) -> CGRect {
        return self.bounds
    }
    
    private func setUpView() {
        //some view adjustment code, like corner radius
        layer.cornerRadius = 10
        layer.masksToBounds = true
        layer.borderWidth = 1
        
        setUpButtons()
    }
    private func setUpButtons() {
        let contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        
        
        locationButton.layer.borderWidth = 1
        locationButton.layer.cornerRadius = 5
        locationButton.layer.borderColor = tintColor.CGColor
        locationButton.contentEdgeInsets = contentEdgeInsets
        locationButton.setTitleColor(tintColor, forState: .Normal)
        locationButton.setTitleColor(tintColor.colorWithAlphaComponent(0.6), forState: UIControlState.Highlighted)
        locationButton.clipsToBounds = true

        calendarButton.layer.borderWidth = 1
        calendarButton.layer.cornerRadius = 5
        calendarButton.layer.borderColor = tintColor.CGColor
        calendarButton.contentEdgeInsets = contentEdgeInsets
        calendarButton.setTitleColor(tintColor, forState: .Normal)
        calendarButton.setTitleColor(tintColor.colorWithAlphaComponent(0.6), forState: UIControlState.Highlighted)
        calendarButton.clipsToBounds = true

        
        notificationButton.layer.borderWidth = 1
        notificationButton.layer.cornerRadius = 5
        notificationButton.layer.borderColor = tintColor.CGColor
        notificationButton.contentEdgeInsets = contentEdgeInsets
        notificationButton.clipsToBounds = true

    }
    
    func updateStateOfButtons(state: StatusOfPermissions) {
        latestPermissionConfiguration = state
        tintButtonsBasedOnLatestPermissionStatus()
    }
    
    private func tintButtonsBasedOnLatestPermissionStatus() {
        if let state = latestPermissionConfiguration {
            locationCheckmark.hidden = !state.permissionLocationGranted
            locationButton.enabled = !state.permissionLocationGranted
            
            calendarChackmark.hidden = !state.permissionCalendarGranted
            calendarButton.enabled = !state.permissionCalendarGranted
            
            notificationCheckmark.hidden = !state.permissionNotificationGranted
            notificationButton.enabled = !state.permissionNotificationGranted
            
            let newColorForLocationPermissionButton = state.permissionLocationGranted ? colorForCheckedButtons : tintColor
            let newColorForCalendarPermissionButton = state.permissionCalendarGranted ? colorForCheckedButtons : tintColor
            let newColorForNotificationPermissionButton = state.permissionNotificationGranted ? colorForCheckedButtons : tintColor
            
            //tinting the buttons
            tintButtonIntoColor(newColorForLocationPermissionButton, button: locationButton)
            tintButtonIntoColor(newColorForCalendarPermissionButton, button: calendarButton)
            tintButtonIntoColor(newColorForNotificationPermissionButton, button: notificationButton)
            
            //tinting the checkmarks
            locationCheckmark.tintColor = newColorForLocationPermissionButton
            calendarChackmark.tintColor = newColorForCalendarPermissionButton
            notificationCheckmark.tintColor = newColorForNotificationPermissionButton
            
        }
    }
    
    
    
    private func tintButtonIntoColor(color: UIColor, button: UIButton) {
//        let newColor = (checked) ? UIColor.colorFromHex(0x1CAD04, alpha: 1) : HelperClass.tintColor
        
        button.setTitleColor(color, forState: .Normal)
        button.setTitleColor(color.colorWithAlphaComponent(0.6), forState: UIControlState.Highlighted)
        button.layer.borderColor = color.CGColor
        button.imageView?.tintColor = color
        if let image = button.imageView?.image {
            button.imageView?.image? = image.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        }
        
    }
    
    
    private func imageInsetsForButton(button: UIButton) -> UIEdgeInsets {
        let offsetForLocationButtonImage = button.frame.width - button.titleLabel!.frame.width - (button.imageView!.frame.width + button.contentEdgeInsets.left)
        
        return UIEdgeInsets(top: 0, left: -offsetForLocationButtonImage, bottom: 0, right: 0)
    }
}
