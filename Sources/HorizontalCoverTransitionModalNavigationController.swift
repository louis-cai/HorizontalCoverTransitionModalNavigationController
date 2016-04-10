//
//  HorizontalCoverTransitionModalNavigationController.swift
//  HorizontalCoverTransitionModalNavigationController
//
//  Created by Moch Xiao on 4/10/16.
//  Copyright © @2016 Moch Xiao (http://mochxiao.com).
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

// MARK: - HorizontalCoverTransitionModalNavigationController

private var paning = false
public final class HorizontalCoverTransitionModalNavigationController: UINavigationController {
    /// Choose one of  The following properties Privode your preferred dismissal item appearance.
    /// Privode your preferred dismissal item title, default is a `.Cancel` style UIBarButtonItem.
    public var preferredDismissBarButtonItemTitle: String?
    /// Privode your preferred dismissal item image, default is a `.Cancel` style UIBarButtonItem.
    public var preferredDismissBarButtonItemImage: UIImage?
    
    private var interactiveTransition: UIPercentDrivenInteractiveTransition?
    private lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let panGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handlePanAction(_:)))
        panGestureRecognizer.edges = .Left
        panGestureRecognizer.delegate = self
        return panGestureRecognizer
    }()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        transitioningDelegate = self
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let rootViewController = viewControllers.first {
            var leftBarButtonItem: UIBarButtonItem!
            if let preferredDismissBarButtonItemTitle = preferredDismissBarButtonItemTitle {
                leftBarButtonItem = UIBarButtonItem(title: preferredDismissBarButtonItemTitle, style: .Plain, target: self, action: #selector(back))
            } else if let preferredDismissBarButtonItemImage = preferredDismissBarButtonItemImage {
                leftBarButtonItem = UIBarButtonItem(image: preferredDismissBarButtonItemImage, style: .Plain, target: self, action: #selector(back))
            } else {
                leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(back))
            }
            rootViewController.navigationItem.leftBarButtonItem = leftBarButtonItem
            
            rootViewController.view.addGestureRecognizer(panGestureRecognizer)
        }
    }
    
    dynamic internal func back() {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    internal func handlePanAction(sender: UIPanGestureRecognizer) {
        let state = sender.state
        if state == .Began {
            paning = true
            if sender.velocityInView(view).x > 0 {
                interactiveTransition = UIPercentDrivenInteractiveTransition()
                back()
            }
        } else {
            let percentComplete = fabs(sender.translationInView(view).x / CGRectGetWidth(view.bounds))
            
            if state == .Changed {
                interactiveTransition?.updateInteractiveTransition(percentComplete)
            } else if state == .Ended {
                paning = false
                
                if percentComplete > 0.5 || sender.velocityInView(view).x > 0 {
                    interactiveTransition?.finishInteractiveTransition()
                } else {
                    interactiveTransition?.cancelInteractiveTransition()
                }
                
                interactiveTransition = nil
            }
        }
    }
}

// MARK: - UIViewControllerTransitioningDelegate

extension HorizontalCoverTransitionModalNavigationController: UIViewControllerTransitioningDelegate {
    public func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentAnimator()
    }
    
    public func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator()
    }
    
    public func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveTransition
    }
}

// MARK: - UIViewControllerAnimatedTransitioning

public final class PresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    public func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.25
    }
    
    public func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard let container = transitionContext.containerView() else {
            return transitionContext.completeTransition(false)
        }
        guard let to = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) else {
            return transitionContext.completeTransition(false)
        }
        guard let from = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) else {
            return transitionContext.completeTransition(false)
        }
        
        to.view.setLeftEdgeShadow()
        
        let finalFrame = transitionContext.finalFrameForViewController(to)
        to.view.frame = finalFrame
        container.addSubview(to.view)
        
        to.view.transform = CGAffineTransformMakeTranslation(CGRectGetWidth(to.view.bounds), 0)
        UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, options: paning ? .CurveLinear : .CurveEaseInOut, animations: {
            to.view.transform = CGAffineTransformIdentity
            from.view.transform = CGAffineTransformMakeTranslation(-ceil(CGRectGetWidth(from.view.bounds) * 0.3), 0)
        }) { _ in
            from.view.transform = CGAffineTransformIdentity
            // If cancel animation, recover the toViewController's position
            to.view.transform = CGAffineTransformIdentity
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        }
    }
}

public final class DismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    public func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.25
    }
    
    public func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard let container = transitionContext.containerView() else {
            return transitionContext.completeTransition(false)
        }
        guard let to = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) else {
            return transitionContext.completeTransition(false)
        }
        guard let from = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) else {
            return transitionContext.completeTransition(false)
        }
        
        let finalFrame = transitionContext.finalFrameForViewController(to)
        to.view.frame = finalFrame
        container.addSubview(to.view)
        container.sendSubviewToBack(to.view)
        
        to.view.transform = CGAffineTransformMakeTranslation(-ceil(CGRectGetWidth(from.view.bounds) * 0.3), 0)
        UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, options: paning ? .CurveLinear : .CurveEaseInOut, animations: {
            from.view.transform = CGAffineTransformMakeTranslation(CGRectGetWidth(to.view.bounds), 0)
            to.view.transform = CGAffineTransformIdentity
        }) { _ in
            from.view.transform = CGAffineTransformIdentity
            // If cancel animation, recover the toViewController's position
            to.view.transform = CGAffineTransformIdentity
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        }
    }
}

private extension UIView {
    private func setLeftEdgeShadow() {
        let path = UIBezierPath(rect: bounds)
        layer.shadowPath = path.CGPath
        layer.shadowOffset = CGSizeMake(-4.0, 0.0)
        layer.shadowColor = UIColor.grayColor().CGColor
        layer.shadowRadius = 4.0
        layer.shadowOpacity = 0.4
    }
}

// MARK: - UIGestureRecognizerDelegate

extension HorizontalCoverTransitionModalNavigationController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer == panGestureRecognizer
    }
}