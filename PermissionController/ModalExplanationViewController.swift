//
//  ModalExplanationViewController.swift
//  ClubNews
//
//  Created by Andreas Neusüß on 22.03.15.
//  Copyright (c) 2015 Anerma. All rights reserved.
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
final public class ModalExplanationViewController: UIViewController {
    
    
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
    
    /**
     Enum that defines possible states of the view.
     
     - Default:      Default position.
     - RotatedLeft:  The view is rotated left: by M_PI_2 clockwise.
     - RotatedRight: The view is rotated right: by M_PI_2 counter clockwise.
     */
    enum ExplanationViewPosition: Int {
        /// Default position.
        case Default
        /// The view is rotated left: by M_PI_2 clockwise.
        case RotatedLeft
        /// The view is rotated right: by M_PI_2 counter clockwise.
        case RotatedRight
        
        /**
         Calculates the center of the view based on its current state (rotation).
         
         - parameter center:           The center of views superview
         - parameter offsetFromCenter: Offset from the views superviews center (usually below the lower bound of the screen)
         
         - returns: The center of the view based on its current state (rotation).
         */
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
        
        /**
         Translates the rotation (cases of enum) into CGAffineTransform that can be applied to the view.
         
         - returns: CGAffineTransform, a rotation clockwise or counter clockwise depending on the current state.
         */
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

    
    override public func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor(white: 0, alpha: 0.5)
    }
    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }


    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /**
     This method starts the presentation of specified views in the typical animated and interactive way. The ViewController transition will be started in this method. Therefore, you just have to call it and the transition/animation begins.
     
     - parameter viewController: The ViewController that is currently presented an will be overlaid by the new ViewController.
     - parameter nameOfNibs:     Name of the nibs that will be presented and animated.
     - parameter completion:     A completion block that will be executed when the interaction has finished: the user has swiped through the views (from right to left, every view was presented, `finishedWithSuccess=true` or dismissed the first one (first view came from right and was pushed rightwards, too, `finishedWithSuccess=false`).
     */
    public func presentExplanationViewControllerOnViewController(viewController : UIViewController, nameOfNibs: [String], completion:((finishedWithSuccess : Bool)->())?) {
        self.nameOfNibs = nameOfNibs
        
        self.completion = completion
        
        self.modalPresentationStyle = .OverFullScreen
        self.modalTransitionStyle = .CrossDissolve
        
        viewController.presentViewController(self, animated: true) { () -> Void in
            self.setupAnimator()
        }
    }
    
    // MARK: - Setup Everything
    
    /**
     Sets up the UIDynamicAnimator and attaches the first view as well as the gestureRecognizer.
     */
    private func setupAnimator() {
        animator = UIDynamicAnimator(referenceView: self.view)
        
        self.addBehaiviorsAndViewForIndex(0, position: .RotatedRight)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(ModalExplanationViewController.panExplanationView(_:)))
        self.view.addGestureRecognizer(pan)
    }
    
    /**
     Adds UIDynamics behaviors to a view at a given index. Therefore, a new view is loaded from nib (using `createExplanationViewForIndex()`). The new view is added to the view hierarchy, constraints are added and it prepared for presentation by using `resetExplanationView()`.
     
     - parameter nextIndex: Index of the next view that should be loaded from a nib. The name is stored in the global `nameOfNibs` array.
     - parameter position:  Position in which the new view should be started from (`.RotatedRight` in most cases)
     */
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

    /**
     Creates a new view and configures it. If you want to use custom views, put your custom preparation code in here.
     For now, if a `PermissionView` is loaded, the button are linked to their actions and styled using the method `updateButtonAppearenceBasedOnCurrentSetOfPermissions()`.
     The view itself is loaded from a nib, its name is specified in the `nameOfNibs` array.
     
     - parameter index: Index of the view in the `nameOfNibs` array.
     
     - returns: A styled and configured UIView if the nib name was valid, nil if not.
     */
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
    /**
     This method is being called when any authorization status has changed. It asks the `permissionActionHandler` about the current set of granted permissions and forwards it to the currently displayed view that will update its UI accordingly.
     */
    @objc private func updateButtonAppearenceBasedOnCurrentSetOfPermissions() {
        //update the buttons.
        
        if let statusOfPermissions = permissionActionHandler?.stateOfPermissions(), let currentPermissionView = currentExplanationView as? PermissionView  {
            
            currentPermissionView.updateStateOfButtons(statusOfPermissions)
            
//            currentPermissionView.locationButton.enabled = !statusOfPermissions.permissionLocationGranted
//            currentPermissionView.calendarButton.enabled = !statusOfPermissions.permissionCalendarGranted
//            currentPermissionView.notificationButton.enabled = !statusOfPermissions.permissionNotificationGranted
        }
    }
    
    //MARK: - Rotation Handlers
    
    override public func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        
        coordinator.animateAlongsideTransition({ context in
            /*
             Basically we need to update the view to match the new orientation.
             Therefore we remove behaviors, update and add them again.
             Additionally, we remove constraints from the old orientation and add new ones to reflect the size change.
             */
            
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
    
    /**
     Convenience method for creating a UISnapBehavior that is added to the `item` and connects it to the `center`. When the view is attached to a point below the screen and snapped into the center, we achieve our desired rotation effect.
     
     - parameter center: Point to which the spring should snap to.
     - parameter item:   The `UIView` to which the spring is applied.
     
     - returns: A UISnapBehavior attached to the specified view snapping it to the specified center.
     */
    private func snapBehaviorForCenter(center: CGPoint, item: UIView) -> UISnapBehavior {
        return UISnapBehavior(item: item, snapToPoint: center)
    }
    
    /**
     Convenience method for creating a UIAttachmentBehavior that is added to the `item`. It attaches the view to a point moved in y direction downwards by `offsetForExplanationView`. When the view is attached to a point below the screen and snapped into the center, we achieve our desired rotation effect.
     
     - parameter center: The center to which the item should be attached to. It will be moved downwards in y direction.
     - parameter item:   The `UIView` to which the spring is applied.
     
     - returns: A UIAttachmentBehavior that attaches the `item` to a point below the screen (specified by `center` and moved downwards by `offsetForExplanationView`.
     */
    private func attachmentBehaviorForCenter(center: CGPoint, item: UIView) -> UIAttachmentBehavior {
        var newCenter = center
        newCenter.y += offsetForExplanationView
        
        return UIAttachmentBehavior(item: item, offsetFromCenter: UIOffset(horizontal: 0, vertical: offsetForExplanationView), attachedToAnchor: newCenter)
    }
    
    /**
     Convenience method for creating a NSLayoutConstraint that specifies the width of the displayed view. It depends on `isWiderThanHeigh()` to use either `kExplainationViewWidthPercentageLandscape` or `kExplainationViewWidthPercentagePortrait`. The percentage relates to the size of the window-filling superview.
     
     - parameter view: The view in which the smaller view is presented.
     
     - returns: NSLayoutConstraint that specifies width of view.
     */
    private func constraintWidthForExplanationView(view: UIView) -> NSLayoutConstraint {
        let multiplier : CGFloat = isWiderThanHeigh() ? CGFloat(kExplainationViewWidthPercentageLandscape) : CGFloat(kExplainationViewWidthPercentagePortrait)
        
        return NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .Equal, toItem: self.view, attribute: .Width, multiplier: multiplier, constant: 0)
    }
    
    /**
     Convenience method for creating a NSLayoutConstraint that specifies the height of the displayed view. It depends on `isWiderThanHeigh()` to use either `kExplainationViewHeightPercentageLandscape` or `kExplainationViewHeightPercentagePortrait`. The percentage relates to the size of the window-filling superview.
     
     - parameter view: The view in which the smaller view is presented.
     
     - returns: NSLayoutConstraint that specifies height of view.
     */
    private func constraintHeightForExplanationView(view: UIView) -> NSLayoutConstraint {
        let multiplier : CGFloat = isWiderThanHeigh() ? CGFloat(kExplainationViewHeightPercentageLandscape) : CGFloat(kExplainationViewHeightPercentagePortrait)
        
        return NSLayoutConstraint(item: view, attribute: .Height, relatedBy: .Equal, toItem: self.view, attribute: .Height, multiplier: multiplier, constant: 0)
    }
    
    /**
     Method to determine if the screen is oriented in portrait or landscape. To be more generic it only relays on the height and width of the main view.
     
     - returns: True if the view is wider than height.
     */
    private func isWiderThanHeigh() -> Bool {
        return CGRectGetWidth(self.view.bounds) > CGRectGetHeight(self.view.bounds)
    }
    
    /**
     This method is responsible for adding autolayout constraints to the view that is passed into via `view`.
     It adds constraint for positioning (pinned to center) as well as width and height (by using `constraintWidthForExplanationView(view)` and `constraintHeightForExplanationView(view)`.
     
     - parameter view: The view to which the constraint should be applied to. Not the view of the ViewController, tough.
     */
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
    /**
     This method handles the pan gesture that the user performs on the currently presented view.
     
     - parameter pan: The UIPanGestureRecognizer that has fired.
     */
    func panExplanationView(pan: UIPanGestureRecognizer) {
        let location = pan.locationInView(self.view)
        let velocity = pan.velocityInView(self.view).x
        
        switch pan.state {
        case .Began:
            //Remove snap behavior and attach pan to reflect the users gesture on the view.
            animator.removeBehavior(snapBehavior)
            panBehavior = UIAttachmentBehavior(item: self.currentExplanationView, attachedToAnchor: location)
            animator.addBehavior(panBehavior)
            
            
        case .Changed:
            //Update the anchorPoint of the pan behavior to the current place of users finger.
            panBehavior.anchorPoint = location
            
        case .Ended:
            fallthrough
            
        case .Cancelled:
            let center = CGPoint(x: CGRectGetWidth(view.bounds)/2, y: CGRectGetHeight(view.bounds)/2)
            let travelledDistance = location.x - center.x
            
            
            /*
             Dismiss the view if certain conditions are met:
             - the view was moved more than 80pt in x direction
             or
             - the view was flicked away with a velocity greater than 800
             and
             - the user has moved the view in the direction he moves it right now (velocity in direction of pan gesture)
            */
            if (fabs(travelledDistance) > 80 || abs(velocity) > 800) && floatsHaveSameSign(travelledDistance, num2: velocity) {
                
                //index of the next view that will be loaded and presented
                var nextIndex = self.index
                
                //position of the current view
                var position = ExplanationViewPosition.RotatedRight
                
                ////position of the next view that will be loaded and presented
                var nextPosition = ExplanationViewPosition.RotatedLeft
                
                
                if velocity > 0 && travelledDistance > 0 {
                    //the user has swiped the view to the right side, the previous view needs to be loaded
                    nextIndex -= 1
                    //next view starts rotated left
                    nextPosition = .RotatedLeft
                    
                    //current view is rotated right
                    position = .RotatedRight
                }
                else {
                    //the user has swiped the view to the left side, the next view needs to be loaded
                    nextIndex += 1
                    //next view starts rotated right
                    nextPosition = .RotatedRight
                    //current view is rotated left
                    position = .RotatedLeft
                }
                
                //limit lower bounds to make sure that index doesn't get < 0 and the first view is loaded if so.
                if nextIndex < 0 {
                    nextIndex = 0
                    nextPosition = .RotatedRight
                }
                
                let duration = 0.5
                let center = CGPoint(x: CGRectGetWidth(view.bounds)/2, y: CGRectGetHeight(view.bounds)/2)
                
                panBehavior.anchorPoint = position.viewCenter(center, offsetFromCenter: self.offsetForExplanationView)
                
                //wait a little before the new view is presented
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(duration * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                    
                    if nextIndex >= self.nameOfNibs.count {
                        //finish the interaction if the last view was swiped away. Pass in `true` because the user finished by swiping through all views.
                        self.dismissAndCallCompletionAccordinglyWithSuccess(true)
                    }
                    else {
                        //load and present the next view
                        self.index = nextIndex
                        self.addBehaiviorsAndViewForIndex(nextIndex, position: nextPosition)
                        
                    }
                })

            }
            else {
                //snap back to center as the user has not dismissed the view.
                animator.removeBehavior(panBehavior)
                animator.addBehavior(snapBehavior)
            }
        default:
            ()
        }
    }

    /**
     This function checks if two floats have the same sign.
     
     - parameter num1: First number
     - parameter num2: Second number
     
     - returns: `True` if both numbers have the same sign (-1 and -3), `false` if not (-1 and 3).
     */
    private func floatsHaveSameSign(num1 : CGFloat, num2 : CGFloat) ->Bool {
        return (num1 < 0 && num2 < 0) || (num1 > 0 && num2 > 0)
    }
    
    
    //MARK: - Button Methods
    
    /**
     The user pressed a skip button, all the views will be skipped and the completion handler will be called with unfinished flag.
     */
    func skipButtonPressed() {
        self.animator.removeAllBehaviors()
        self.animateTheCurrentViewToPosition(ExplanationViewPosition.RotatedLeft, completion: { () -> Void in
            self.dismissAndCallCompletionAccordinglyWithSuccess(false)
        })
    }
    /**
     The user pressed done button, the last view was presented and now the completion handler will be called with finished flag.
     */
    func doneButtonPressed() {
        self.animator.removeAllBehaviors()
        self.animateTheCurrentViewToPosition(ExplanationViewPosition.RotatedLeft, completion: { () -> Void in
            self.dismissAndCallCompletionAccordinglyWithSuccess(true)
        })
    }
    /**
     The user pressed a decline button, all the views will be skipped and the completion handler will be called with unfinished flag.
     */
    func declineButtonPressed() {
        self.animator.removeAllBehaviors()
        self.animateTheCurrentViewToPosition(ExplanationViewPosition.RotatedRight, completion: { () -> Void in
            self.dismissAndCallCompletionAccordinglyWithSuccess(false)
        })
    }
    
    /**
     The user pressed a back button which will cause the next view being loaded and presented using an animation.
     */
    func backButtonPressed() {
        self.animator.removeAllBehaviors()
        
        self.animateTheCurrentViewToPosition(ExplanationViewPosition.RotatedRight, completion: { () -> Void in
            self.index -= 1
            self.addBehaiviorsAndViewForIndex(self.index, position: ExplanationViewPosition.RotatedLeft)
        })
        
    }
    
    /**
     The user pressed a skip button which will cause the next view being loaded and presented using an animation.
     */
    func continueButtonPressed() {
        self.animator.removeAllBehaviors()
        
        self.animateTheCurrentViewToPosition(ExplanationViewPosition.RotatedLeft, completion: { () -> Void in
            self.index += 1
            self.addBehaiviorsAndViewForIndex(self.index, position: ExplanationViewPosition.RotatedRight)
        })
    }
    
    /**
     Function that wraps a call to the `permissionActionHandler`. It is called when the location permission button is pressed and asks the `permissionActionHandler` to handle the action.
     */
    func permissionButtonLocationPressed() {
        permissionActionHandler?.permissionButtonLocationPressed()
    }
    /**
     Function that wraps a call to the `permissionActionHandler`. It is called when the calendar permission button is pressed and asks the `permissionActionHandler` to handle the action.
     */
    func permissionButtonCalendarPressed() {
        permissionActionHandler?.permissionButtonCalendarPressed()
    }
    /**
     Function that wraps a call to the `permissionActionHandler`. It is called when the notification permission button is pressed and asks the `permissionActionHandler` to handle the action.
     */
    func permissionButtonNotificationPressed() {
        permissionActionHandler?.permissionButtonNotificationPressed()
    }
    
    /**
     This method animates the current view into a given position. The animation looks like the user has performed the swipe but in reality it is a static animation. Use this method if you want to dismiss a view programatically and animated.
     
     - parameter position:   The position in which the current view should be animated to.
     - parameter completion: Completion handler that is called after the animation finished.
     */
    private func animateTheCurrentViewToPosition(position: ExplanationViewPosition, completion:(()->Void)) {
        
        //Basically we want the view to be rotated and translated, animated.
        
        let offsetToAddOrSubstract : CGFloat = (position == ExplanationViewPosition.RotatedLeft) ? -150 : 150
        
        UIView.animateWithDuration(0.7, delay: 0, usingSpringWithDamping: 1.5, initialSpringVelocity: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: { () -> Void in
            
            self.currentExplanationView.center = position.viewCenter(CGPoint(x: (CGRectGetWidth(self.view.bounds) / 2) + offsetToAddOrSubstract, y: CGRectGetHeight(self.view.bounds)/2), offsetFromCenter: self.offsetForExplanationView)
            
            self.currentExplanationView.transform = position.viewTransform()
            
            }) { (_) -> Void in
                completion()
        }
    }
    
    /**
     Resets a given view to default values and adds default behaviors. Thereby it is placed below the screen and rotated to the given direction.
     
     - parameter explanationView: The view that shall be reset
     - parameter position:        Position to which the new view should be reset to.
     */
    private func resetExplanationView(explanationView: UIView, position: ExplanationViewPosition) {
        animator.removeAllBehaviors()
        
        let center = CGPoint(x: CGRectGetWidth(view.bounds)/2, y: CGRectGetHeight(view.bounds)/2)
        explanationView.center = position.viewCenter(center , offsetFromCenter: offsetForExplanationView)
        explanationView.transform = position.viewTransform()
        
        animator.updateItemUsingCurrentState(explanationView)
        
        animator.addBehavior(attachmentBehavior)
        animator.addBehavior(snapBehavior)
    }

    /**
     Call this method to finish the presentation. It will dismiss the ´ViewController` and call a provided completion handler with `finishedWithSuccess` set to `true` if the user has viewed all of the provided views or `false` if he skipped or cancelled.
     
     - parameter success: Flag that indicates whether the user has seen any provided view or skipped them. `true` if the user has viewed all of the provided views or `false` if he skipped or cancelled.
     */
    private func dismissAndCallCompletionAccordinglyWithSuccess(success: Bool) {
        self.dismissViewControllerAnimated(true, completion: {
            
            self.completion?(finishedWithSuccess: success)
        })
    }
}
