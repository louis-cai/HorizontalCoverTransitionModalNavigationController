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
    
    fileprivate var interactiveTransition: UIPercentDrivenInteractiveTransition?
    fileprivate lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let panGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handlePanAction(_:)))
        panGestureRecognizer.edges = .left
        panGestureRecognizer.delegate = self
        return panGestureRecognizer
    }()
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }
    
    override public init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    fileprivate func setup() {
        transitioningDelegate = self
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let rootViewController = viewControllers.first {
            var leftBarButtonItem: UIBarButtonItem!
            if let preferredDismissBarButtonItemTitle = preferredDismissBarButtonItemTitle {
                leftBarButtonItem = UIBarButtonItem(title: preferredDismissBarButtonItemTitle, style: .plain, target: self, action: #selector(back))
            } else if let preferredDismissBarButtonItemImage = preferredDismissBarButtonItemImage {
                leftBarButtonItem = UIBarButtonItem(image: preferredDismissBarButtonItemImage, style: .plain, target: self, action: #selector(back))
            } else {
                leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(back))
            }
            rootViewController.navigationItem.leftBarButtonItem = leftBarButtonItem
            
            rootViewController.view.addGestureRecognizer(panGestureRecognizer)
        }
    }
    
    @objc dynamic internal func back() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc internal func handlePanAction(_ sender: UIPanGestureRecognizer) {
        let state = sender.state
        if state == .began {
            paning = true
            if sender.velocity(in: view).x > 0 {
                interactiveTransition = UIPercentDrivenInteractiveTransition()
                back()
            }
        } else {
            let percentComplete = abs(sender.translation(in: view).x / view.bounds.width)
            
            if state == .changed {
                interactiveTransition?.update(percentComplete)
            } else if state == .ended {
                paning = false
                
                if percentComplete > 0.5 || sender.velocity(in: view).x > 0 {
                    interactiveTransition?.finish()
                } else {
                    interactiveTransition?.cancel()
                }
                
                interactiveTransition = nil
            }
        }
    }
}

// MARK: - UIViewControllerTransitioningDelegate

extension HorizontalCoverTransitionModalNavigationController: UIViewControllerTransitioningDelegate {
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentAnimator()
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator()
    }
    
    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveTransition
    }
}

// MARK: - UIViewControllerAnimatedTransitioning

public final class PresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let to = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {
            return transitionContext.completeTransition(false)
        }
        guard let from = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) else {
            return transitionContext.completeTransition(false)
        }
        
        to.view.setLeftEdgeShadow()
        
        let container = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: to)
        to.view.frame = finalFrame
        container.addSubview(to.view)
        
        to.view.transform = CGAffineTransform(translationX: to.view.bounds.width, y: 0)
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: paning ? .curveLinear : UIView.AnimationOptions(), animations: {
            to.view.transform = CGAffineTransform.identity
            from.view.transform = CGAffineTransform(translationX: -ceil(from.view.bounds.width * 0.3), y: 0)
        }) { _ in
            from.view.transform = CGAffineTransform.identity
            // If cancel animation, recover the toViewController's position
            to.view.transform = CGAffineTransform.identity
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

public final class DismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let to = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {
            return transitionContext.completeTransition(false)
        }
        guard let from = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) else {
            return transitionContext.completeTransition(false)
        }
        
        let container = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: to)
        to.view.frame = finalFrame
        container.addSubview(to.view)
        container.sendSubviewToBack(to.view)
        
        to.view.transform = CGAffineTransform(translationX: -ceil(from.view.bounds.width * 0.3), y: 0)
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: paning ? .curveLinear : UIView.AnimationOptions(), animations: {
            from.view.transform = CGAffineTransform(translationX: to.view.bounds.width, y: 0)
            to.view.transform = CGAffineTransform.identity
        }) { _ in
            from.view.transform = CGAffineTransform.identity
            // If cancel animation, recover the toViewController's position
            to.view.transform = CGAffineTransform.identity
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

private extension UIView {
    func setLeftEdgeShadow() {
        let path = UIBezierPath(rect: bounds)
        layer.shadowPath = path.cgPath
        layer.shadowOffset = CGSize(width: -4.0, height: 68)
        layer.shadowColor = UIColor.gray.cgColor
        layer.shadowRadius = 4.0
        layer.shadowOpacity = 0.4
    }
}

// MARK: - UIGestureRecognizerDelegate

extension HorizontalCoverTransitionModalNavigationController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer == panGestureRecognizer
    }
}
