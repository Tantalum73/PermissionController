//
//  ModalExplanationViewController.swift
//  ClubNews
//
//  Created by Andreas Neusüß on 22.03.15.
//  Copyright (c) 2015 Cocoawah. All rights reserved.
//

import UIKit

private let kExplanationViewHeight = 400
private let kExplanationViewWidth = 300

private let kExplanationViewOffset : CGFloat = 500

struct StatusOfPermissions {
    //TODO: evtl. enum to express more values
    //TODO: save global state fo this struct to disk to prevent from checking every time again
    var permissionLocationGranted = false
    var permissionCalendarGranted = false
    var permissionNotificationGranted = false
}

protocol PermissionAskingProtocol {
    func stateOfPermissions() -> StatusOfPermissions
    func permissionButtonLocationPressed()
    func permissionButtonCalendarPressed()
    func permissionButtonNotificationPressed()
}

class ModalExplanationViewController: UIViewController {
    
    
    
    var permissionActionHandler : PermissionAskingProtocol?
    
    private var nameOfNibs : [String]!
    private var completion : ((finishedWithSuccess : Bool)->())?
    
    private var animator : UIDynamicAnimator!
    private var attachmentBehavior : UIAttachmentBehavior!
    private var snapBehavior : UISnapBehavior!
    private var panBehavior : UIAttachmentBehavior!
    private var currentExplanationView : UIView!
    
    private var index = 0
    
    
    enum ExplanationViewPosition: Int {
        case Default
        case RotatedLeft
        case RotatedRight
        
        func viewCenter(var center: CGPoint)->CGPoint {
            switch self {
            case .RotatedLeft:
                center.y += kExplanationViewOffset
                center.x -= kExplanationViewOffset
            case .RotatedRight:
                center.y += kExplanationViewOffset
                center.x += kExplanationViewOffset
                
            default:
                ()
            }
            
            return center
        }
        
        func viewTransform() -> CGAffineTransform {
            switch self {
            case .RotatedRight:
                return CGAffineTransformMakeRotation(CGFloat(M_PI_2))
            case .RotatedLeft:
                return CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
            default:
                return CGAffineTransformIdentity
            }
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor(white: 0, alpha: 0.5)
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func presentExplanationViewControllerOnViewController(viewController : UIViewController, nameOfNibs: [String], completion:((finishedWithSuccess : Bool)->())?) {
        self.nameOfNibs = nameOfNibs
        
        self.completion = completion
        
        self.modalPresentationStyle = .OverFullScreen
        self.modalTransitionStyle = .CrossDissolve
        
        viewController.presentViewController(self, animated: true) { () -> Void in
            self.setupAnimator()
        }
    }
    
    // MARK: - Setup Everything
    
    private func setupAnimator() {
        animator = UIDynamicAnimator(referenceView: self.view)
        
        self.addBehaiviorsAndViewForIndex(0, position: .RotatedRight)
        
        let pan = UIPanGestureRecognizer(target: self, action: "panExplanationView:")
        self.view.addGestureRecognizer(pan)
    }
    
    private func addBehaiviorsAndViewForIndex(nextIndex:Int, position: ExplanationViewPosition) {
        
        
        if(nextIndex >= self.nameOfNibs.count) {
            self.skipButtonPressed()
            return
        }
        
        if self.currentExplanationView != nil {
            self.currentExplanationView.removeFromSuperview()
        }
        
        var newView = self.createExplanationViewForIndex(nextIndex)!
        
        self.view.addSubview(newView)
        var center = CGPoint(x: CGRectGetWidth(view.bounds)/2, y: CGRectGetHeight(view.bounds)/2)
        snapBehavior = UISnapBehavior(item: newView, snapToPoint: center)
        center.y += kExplanationViewOffset
        
        attachmentBehavior = UIAttachmentBehavior(item: newView, offsetFromCenter: UIOffset(horizontal: 0, vertical: kExplanationViewOffset), attachedToAnchor: center)
        resetExplanationView(self.currentExplanationView, position: position)
    }

    private func createExplanationViewForIndex(index: Int) -> UIView? {
        let generalView: UIView = UINib(nibName: String(self.nameOfNibs[index]), bundle: nil).instantiateWithOwner(nil, options: nil).first as! UIView
        
        generalView.frame = CGRect(x: 0, y: 0, width: kExplanationViewWidth, height: kExplanationViewHeight)
        
        //Setting up global Properties on ExplanationViews:
        
        currentExplanationView = generalView
       
        if let correctView = generalView as? PermissionView {

            NSNotificationCenter.defaultCenter().addObserver(self, selector:"updateButtonAppearenceBasedOnCurrentSetOfPermissions" , name: "AuthorizationStatusChanged", object: nil)
            
            correctView.progressView.progress = 1.0
            correctView.locationButton.addTarget(self, action: "permissionButtonLocationPressed", forControlEvents: .TouchUpInside)
            correctView.calendarButton.addTarget(self, action: "permissionButtonCalendarPressed", forControlEvents: .TouchUpInside)
            correctView.notificationButton.addTarget(self, action: "permissionButtonNotificationPressed", forControlEvents: .TouchUpInside)
            correctView.doneButton.addTarget(self, action: "doneButtonPressed", forControlEvents: .TouchUpInside)
            updateButtonAppearenceBasedOnCurrentSetOfPermissions()
        }
        
        return generalView

    }
    func updateButtonAppearenceBasedOnCurrentSetOfPermissions() {
        //update the buttons.
        
        if let statusOfPermissions = permissionActionHandler?.stateOfPermissions(), let currentPermissionView = currentExplanationView as? PermissionView  {
            
            currentPermissionView.updateStateOfButtons(statusOfPermissions)
            
//            currentPermissionView.locationButton.enabled = !statusOfPermissions.permissionLocationGranted
//            currentPermissionView.calendarButton.enabled = !statusOfPermissions.permissionCalendarGranted
//            currentPermissionView.notificationButton.enabled = !statusOfPermissions.permissionNotificationGranted
        }
    }
    
    
    
    //MARK: - GestureRecognizer Action Methods
    func panExplanationView(pan: UIPanGestureRecognizer) {
        let location = pan.locationInView(self.view)
        let velocity = pan.velocityInView(self.view).x
        
        switch pan.state {
        case .Began:
            animator.removeBehavior(snapBehavior)
            panBehavior = UIAttachmentBehavior(item: self.currentExplanationView, attachedToAnchor: location)
            animator.addBehavior(panBehavior)
            
        case .Changed:
            panBehavior.anchorPoint = location
        case .Ended:
            fallthrough
        case .Cancelled:
            let center = CGPoint(x: CGRectGetWidth(view.bounds)/2, y: CGRectGetHeight(view.bounds)/2)
            let offset = location.x - center.x
            
            if (fabs(offset) > 80 || abs(velocity) > 800) && floatsHaveSameSign(offset, num2: velocity) {
                var nextIndex = self.index
                var position = ExplanationViewPosition.RotatedRight
                var nextPosition = ExplanationViewPosition.RotatedLeft
                
                if velocity > 0 && offset > 0 {
                    nextIndex--
                    nextPosition = .RotatedLeft
                    position = .RotatedRight
                }
                else {
                    nextIndex++
                    nextPosition = .RotatedRight
                    position = .RotatedLeft
                }
                
                if nextIndex < 0 {
                    nextIndex = 0
                    nextPosition = .RotatedRight
                }
                
                let duration = 0.5
                let center = CGPoint(x: CGRectGetWidth(view.bounds)/2, y: CGRectGetHeight(view.bounds)/2)
                
                panBehavior.anchorPoint = position.viewCenter(center)
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(duration * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                    
                    if nextIndex >= self.nameOfNibs.count {
                        self.dismissAndCallCompletionAccordinglyWithSuccess(true)
                        
//                        self.dismissViewControllerAnimated(true, completion: {
//                            
//                            //TODO: send clubs to delegate
//                            self.completion?(finishedWithSuccess: true)
//                        })
                        
                    }
                    else {
                        self.index = nextIndex
                        self.addBehaiviorsAndViewForIndex(nextIndex, position: nextPosition)
                        
                    }
                })

            }
            else {
                
                //snap back to center
                animator.removeBehavior(panBehavior)
                animator.addBehavior(snapBehavior)
            }
        default:
            ()
        }
    }

    func floatsHaveSameSign(num1 : CGFloat, num2 : CGFloat) ->Bool {
        return (num1 < 0 && num2 < 0) || (num1 > 0 && num2 > 0)
    }
    
    //MARK: - Button Methods
    func skipButtonPressed() {
        self.animator.removeAllBehaviors()
        self.animateTheCurrentViewToPosition(ExplanationViewPosition.RotatedLeft, completion: { () -> Void in
            self.dismissAndCallCompletionAccordinglyWithSuccess(false)
//            self.dismissViewControllerAnimated(true, completion: {
//                
//                self.completion?(finishedWithSuccess: false)
//            })
        })
    }
    func doneButtonPressed() {
        self.animator.removeAllBehaviors()
        self.animateTheCurrentViewToPosition(ExplanationViewPosition.RotatedLeft, completion: { () -> Void in
            self.dismissAndCallCompletionAccordinglyWithSuccess(true)
//            self.dismissViewControllerAnimated(true, completion: {
//                
//                self.completion?(finishedWithSuccess: true)
//            })
        })
    }
    func declineButtonPressed() {
        self.animator.removeAllBehaviors()
        self.animateTheCurrentViewToPosition(ExplanationViewPosition.RotatedRight, completion: { () -> Void in
            self.dismissAndCallCompletionAccordinglyWithSuccess(false)
//            self.dismissViewControllerAnimated(true, completion: {
//                
//                self.completion?(finishedWithSuccess: false)
//            })
        })
    }
    
    func backButtonPressed() {
        self.animator.removeAllBehaviors()
        
        self.animateTheCurrentViewToPosition(ExplanationViewPosition.RotatedRight, completion: { () -> Void in
            self.index--
            self.addBehaiviorsAndViewForIndex(self.index, position: ExplanationViewPosition.RotatedLeft)
        })
        
    }
    func continueButtonPressed() {
        self.animator.removeAllBehaviors()
        
        self.animateTheCurrentViewToPosition(ExplanationViewPosition.RotatedLeft, completion: { () -> Void in
            self.index++
            self.addBehaiviorsAndViewForIndex(self.index, position: ExplanationViewPosition.RotatedRight)
        })
    }
    
    func permissionButtonLocationPressed() {
        permissionActionHandler?.permissionButtonLocationPressed()
    }
    func permissionButtonCalendarPressed() {
        permissionActionHandler?.permissionButtonCalendarPressed()
        
    }
    func permissionButtonNotificationPressed() {
        permissionActionHandler?.permissionButtonNotificationPressed()
        
    }
    
    private func animateTheCurrentViewToPosition(position: ExplanationViewPosition, completion:(()->Void)) {
        
        let offsetToAddOrSubstract : CGFloat = (position == ExplanationViewPosition.RotatedLeft) ? -150 : 150
        
        UIView.animateWithDuration(0.7, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: { () -> Void in
            
            self.currentExplanationView.center = position.viewCenter(CGPoint(x: (CGRectGetWidth(self.view.bounds) / 2) + offsetToAddOrSubstract, y: CGRectGetHeight(self.view.bounds)/2))
            
            self.currentExplanationView.transform = position.viewTransform()
            
            }) { (success) -> Void in
                completion()
        }
    }
    
    private func resetExplanationView(ExplanationView: UIView, position: ExplanationViewPosition) {
        animator.removeAllBehaviors()
        
        var center = CGPoint(x: CGRectGetWidth(view.bounds)/2, y: CGRectGetHeight(view.bounds)/2)
        ExplanationView.center = position.viewCenter(center)
        ExplanationView.transform = position.viewTransform()
        
        animator.updateItemUsingCurrentState(ExplanationView)
        
        animator.addBehavior(attachmentBehavior)
        animator.addBehavior(snapBehavior)
    }

    private func dismissAndCallCompletionAccordinglyWithSuccess(success: Bool) {
        self.dismissViewControllerAnimated(true, completion: {
            
            self.completion?(finishedWithSuccess: success)
        })
    }
}
