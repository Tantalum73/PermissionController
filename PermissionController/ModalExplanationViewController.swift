//
//  ModalExplanationViewController.swift
//  ClubNews
//
//  Created by Andreas Neusüß on 22.03.15.
//  Copyright (c) 2015 Cocoawah. All rights reserved.
//

import UIKit


/// Constant that defines the height of the displayed view in portrait modus in percentage of the mainScreen() size.
private let kExplainationViewHeightPercentagePortrait = 0.8
/// Constant that defines the height of the displayed view in landscape modus in percentage of the mainScreen() size.
private let kExplainationViewHeightPercentageLandscape = 0.9

/// Constant that defines the width of the displayed view in portrait modus in percentage of the mainScreen() size.
private let kExplainationViewWidthPercentagePortrait = 0.9

/// Constant that defines the width of the displayed view in landscape modus in percentage of the mainScreen() size.
private let kExplainationViewWidthPercentageLandscape = 0.9


/**
 *  Struct that captures state of the permissions that are granted or not.
 */
struct StatusOfPermissions {
    //TODO: evtl. enum to express more values
    //TODO: save global state of this struct to disk to prevent from checking every time again
    
        /// User has allowed the app to use their location.
    var permissionLocationGranted = false
        /// User has allowed the app to use their calendar.
    var permissionCalendarGranted = false
        /// User has allowed the app to use send them notifications.
    var permissionNotificationGranted = false
}

/**
 *  Implement this protocol if you want to provide methods that handle button presses. It also must provide the current state of permissions as a StatusOfPermissions struct.
 */
protocol PermissionAskingProtocol {
    /**
     Captures the current state of permissions. The implementing method gathers whether StatusOfPermissions struct that encapsulates if the user has granted or declined permissions (eg for location or notification access).
     
     - returns: StatusOfPermissions that encapsulates the current permission statuses.
     */
    func stateOfPermissions() -> StatusOfPermissions
    
    /**
     This method will be called when the user taps on the 'request location permission' button in the view.
     */
    func permissionButtonLocationPressed()
    /**
     This method will be called when the user taps on the 'request calendar access permission' button in the view.
     */
    func permissionButtonCalendarPressed()
    /**
     This method will be called when the user taps on the 'request notification permission' button in the view.
     */
    func permissionButtonNotificationPressed()
}

/// ModalExplanationViewController is responsible for presenting the PermissionView and handling user interactions like swiping or tapping on a button.
class ModalExplanationViewController: UIViewController {
    
    
        /// The permissionActionHandler is of type PermissionAskingProtocol and is needed to populate the view with the current permission statuses as well as acting on button-action methods.
    var permissionActionHandler : PermissionAskingProtocol?
    
        /// Name of the nibs that should be presented in this modal-carousel style.
    private var nameOfNibs : [String]!
    
        /// Completion block that is executed after the user has dismissed the dialog.
    private var completion : ((finishedWithSuccess : Bool)->())?
    
        /// Offset by which the presented view will be translated down before animating in.
    private lazy var offsetForExplanationView : CGFloat = {
        let heightOfScreen = UIScreen.mainScreen().bounds.size.height
        
        return heightOfScreen
    }()
    
        /// UIDynamicAnimator for driving the interaction
    private var animator : UIDynamicAnimator!
        /// UIAttachmentBehavior for attaching the view to the bottom and thereby achieving a rotation.
    private var attachmentBehavior : UIAttachmentBehavior!
        /// UISnapBehavior for snapping the view to the center.
    private var snapBehavior : UISnapBehavior!
        ///UIAttachmentBehavior that is attached when the user pans the view.
    private var panBehavior : UIAttachmentBehavior!
        /// The current view that is visible on the screen.
    private var currentExplanationView : UIView!
    
        /// Constraint that defines the width of the view. Derived from kExplainationViewWidthPercentagePortrait and kExplainationViewWidthPercentageLandscape.
    private var widthOfView : NSLayoutConstraint!
    /// Constraint that defines the height of the view. Derived from kExplainationViewHeightPercentagePortrait and kExplainationViewHeightPercentageLandscape.
    private var heightOfView : NSLayoutConstraint!
        /// Constraint that defines the centerX of the view.
    private var centerXOfView : NSLayoutConstraint!
        /// Constraint that defines the centerY of the view.
    private var centerYOfView : NSLayoutConstraint!
    
        /// Index of the currently displayed view.
    private var index = 0
    
    
    enum ExplanationViewPosition: Int {
        case Default
        case RotatedLeft
        case RotatedRight
        
        func viewCenter(center: CGPoint, offsetFromCenter : CGFloat)->CGPoint {
            var center = center
            
            switch self {
            case .RotatedLeft:
                center.y += offsetFromCenter
                center.x -= offsetFromCenter
            case .RotatedRight:
                center.y += offsetFromCenter
                center.x += offsetFromCenter
                
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
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(ModalExplanationViewController.panExplanationView(_:)))
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
        
        let newView = self.createExplanationViewForIndex(nextIndex)!
        
        self.view.addSubview(newView)
        
        let center = CGPoint(x: CGRectGetWidth(view.bounds)/2, y: CGRectGetHeight(view.bounds)/2)
        snapBehavior = self.snapBehaviorForCenter(center, item: newView)
        
        attachmentBehavior = attachmentBehaviorForCenter(center, item: newView)
        resetExplanationView(self.currentExplanationView, position: position)
        
        addConstraintsToNewView(newView)
        newView.transform = CGAffineTransformConcat(newView.transform, CGAffineTransformMakeTranslation(0, -offsetForExplanationView))
    }

    private func createExplanationViewForIndex(index: Int) -> UIView? {
        let generalView: UIView = UINib(nibName: String(self.nameOfNibs[index]), bundle: nil).instantiateWithOwner(nil, options: nil).first as! UIView
        
//        generalView.frame = CGRect(x: 0, y: 0, width: kExplanationViewWidth, height: kExplanationViewHeight)
        
        //Setting up global Properties on ExplanationViews:
        
        currentExplanationView = generalView
       
        if let correctView = generalView as? PermissionView {

            NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(ModalExplanationViewController.updateButtonAppearenceBasedOnCurrentSetOfPermissions) , name: "AuthorizationStatusChanged", object: nil)
            
            correctView.progressView.progress = 1.0
            correctView.locationButton.addTarget(self, action: #selector(ModalExplanationViewController.permissionButtonLocationPressed), forControlEvents: .TouchUpInside)
            correctView.calendarButton.addTarget(self, action: #selector(ModalExplanationViewController.permissionButtonCalendarPressed), forControlEvents: .TouchUpInside)
            correctView.notificationButton.addTarget(self, action: #selector(ModalExplanationViewController.permissionButtonNotificationPressed), forControlEvents: .TouchUpInside)
            correctView.doneButton.addTarget(self, action: #selector(ModalExplanationViewController.doneButtonPressed), forControlEvents: .TouchUpInside)
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
    
    //MARK: - Rotation Handlers
    
    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        
        coordinator.animateAlongsideTransition({ context in
            let snappedView = self.currentExplanationView
            self.animator.removeBehavior(self.snapBehavior)
            self.animator.removeBehavior(self.attachmentBehavior)
            
            let center = CGPoint(x: CGRectGetWidth(self.view.bounds)/2, y: CGRectGetHeight(self.view.bounds)/2)
            self.snapBehavior = self.snapBehaviorForCenter(center, item: snappedView)
            self.attachmentBehavior = self.attachmentBehaviorForCenter(center, item: snappedView)
            
            self.resetExplanationView(snappedView, position: .Default)
            
            self.view.removeConstraint(self.widthOfView)
            self.view.removeConstraint(self.heightOfView)
            
            self.widthOfView = self.constraintWidthForExplanationView(snappedView)
            self.heightOfView = self.constraintHeightForExplanationView(snappedView)
            
            self.view.addConstraint(self.widthOfView)
            self.view.addConstraint(self.heightOfView)
            
            self.view.layoutIfNeeded()
            
            }, completion: ({ context in
                self.view.layoutIfNeeded()
            }))
    }
    
    private func snapBehaviorForCenter(center: CGPoint, item: UIView) -> UISnapBehavior {
        return UISnapBehavior(item: item, snapToPoint: center)
    }
    private func attachmentBehaviorForCenter(center: CGPoint, item: UIView) -> UIAttachmentBehavior {
        var newCenter = center
        newCenter.y += offsetForExplanationView
        
        return UIAttachmentBehavior(item: item, offsetFromCenter: UIOffset(horizontal: 0, vertical: offsetForExplanationView), attachedToAnchor: newCenter)
    }
    private func constraintWidthForExplanationView(view: UIView) -> NSLayoutConstraint {
        let multiplier : CGFloat = isWiderThanHeigh() ? CGFloat(kExplainationViewWidthPercentageLandscape) : CGFloat(kExplainationViewWidthPercentagePortrait)
        
        return NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .Equal, toItem: self.view, attribute: .Width, multiplier: multiplier, constant: 0)
    }
    private func constraintHeightForExplanationView(view: UIView) -> NSLayoutConstraint {
        let multiplier : CGFloat = isWiderThanHeigh() ? CGFloat(kExplainationViewHeightPercentageLandscape) : CGFloat(kExplainationViewHeightPercentagePortrait)
        
        return NSLayoutConstraint(item: view, attribute: .Height, relatedBy: .Equal, toItem: self.view, attribute: .Height, multiplier: multiplier, constant: 0)
    }
    
    private func isWiderThanHeigh() -> Bool {
        return CGRectGetWidth(self.view.bounds) > CGRectGetHeight(self.view.bounds)
    }
    
    private func addConstraintsToNewView(view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        centerXOfView = NSLayoutConstraint(item: view, attribute: .CenterX, relatedBy: .Equal, toItem: self.view, attribute: .CenterX, multiplier: 1, constant: 0)
        
        centerYOfView = NSLayoutConstraint(item: view, attribute: .CenterY, relatedBy: .Equal, toItem: self.view, attribute: .CenterY, multiplier: 1, constant: 0)
        widthOfView = constraintWidthForExplanationView(view)
        
        heightOfView = constraintHeightForExplanationView(view)
        
        self.view.addConstraint(centerXOfView)
        self.view.addConstraint(centerYOfView)
        self.view.addConstraint(heightOfView)
        self.view.addConstraint(widthOfView)
        
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
                    nextIndex -= 1
                    nextPosition = .RotatedLeft
                    position = .RotatedRight
                }
                else {
                    nextIndex += 1
                    nextPosition = .RotatedRight
                    position = .RotatedLeft
                }
                
                if nextIndex < 0 {
                    nextIndex = 0
                    nextPosition = .RotatedRight
                }
                
                let duration = 0.5
                let center = CGPoint(x: CGRectGetWidth(view.bounds)/2, y: CGRectGetHeight(view.bounds)/2)
                
                panBehavior.anchorPoint = position.viewCenter(center, offsetFromCenter: self.offsetForExplanationView)
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
            self.index -= 1
            self.addBehaiviorsAndViewForIndex(self.index, position: ExplanationViewPosition.RotatedLeft)
        })
        
    }
    func continueButtonPressed() {
        self.animator.removeAllBehaviors()
        
        self.animateTheCurrentViewToPosition(ExplanationViewPosition.RotatedLeft, completion: { () -> Void in
            self.index -= 1
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
            
            self.currentExplanationView.center = position.viewCenter(CGPoint(x: (CGRectGetWidth(self.view.bounds) / 2) + offsetToAddOrSubstract, y: CGRectGetHeight(self.view.bounds)/2), offsetFromCenter: self.offsetForExplanationView)
            
            self.currentExplanationView.transform = position.viewTransform()
            
            }) { (success) -> Void in
                completion()
        }
    }
    
    private func resetExplanationView(ExplanationView: UIView, position: ExplanationViewPosition) {
        animator.removeAllBehaviors()
        
        let center = CGPoint(x: CGRectGetWidth(view.bounds)/2, y: CGRectGetHeight(view.bounds)/2)
        ExplanationView.center = position.viewCenter(center , offsetFromCenter: offsetForExplanationView)
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
