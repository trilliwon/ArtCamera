//
//  UIVC+Extensions.swift
//  coffee-camera
//
//  Created by wonjo on 23/05/2018.
//  Copyright © 2018 trilliwon. All rights reserved.
//

import UIKit

extension UIViewController {

    /// Use this if and only if you create storyboard as same name with viewController's file name
    static var instance: UIViewController {
        return UIStoryboard(name: self.className, bundle: nil).instantiateInitialViewController()!
    }
}

extension UIViewController {

    /// start indicator on top right navigation bar
    func startRightBarIndicatorAnimating(style: UIActivityIndicatorView.Style = UIActivityIndicatorView.Style.medium) {
        let indicator = UIActivityIndicatorView(style: style)
        indicator.startAnimating()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: indicator)
    }

    /// stop indicator on top right navigation bar
    func stopRightBarIndicatorAnimating() {
        if
            let rightBarButtonItem = self.navigationItem.rightBarButtonItem,
            let indicator = rightBarButtonItem.customView as? UIActivityIndicatorView {
            indicator.stopAnimating()
            self.navigationItem.rightBarButtonItem = nil
        }
    }
}

extension UIViewController {
    /// This alert controller's style is 'alert' and it has only one action which is 'OK' action
    func alert(title: String = "Notification",
               message: String,
               okTitle: String = "OK", okAction: (() -> Swift.Void)? = nil) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: okTitle, style: .cancel) { _ in
                guard let action = okAction else { return }
                action()
            }

            alert.addAction(okAction)
            alert.view.tintColor = UIColor.default

            self.present(alert, animated: true, completion: { alert.view.tintColor = UIColor.default })
        }
    }

    /// This alert controller's style is 'alert' and it has two actions Which are 'OK' and 'CANCEL'
    func alert(title: String = "Notification",
               message: String,
               cancelTitle: String = "Cancel",
               okTitle: String, okAction: @escaping () -> Void) {

        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: okTitle, style: UIAlertAction.Style.default) { _ in okAction() }
            let cancelAction = UIAlertAction(title: cancelTitle, style: UIAlertAction.Style.cancel)

            alert.addAction(cancelAction)
            alert.addAction(okAction)
            alert.view.tintColor = UIColor.default
            self.present(alert, animated: true, completion: { alert.view.tintColor = UIColor.default })
        }
    }

    /// This alert controller's style is 'actionSheet'
    ///
    /// Make action list and use.
    ///
    ///         let actionSheetActions: [(title: String, action: ((UIAlertAction) -> Void))] =
    ///             [
    ///                 (title: "first action", action: { _ in
    ///                     print("This is frist action.")
    ///                 }),
    ///
    ///                 (title: "second action", action: { _ in
    ///                     print("This is second action.")
    ///                 }),
    ///
    ///                 (title: "third action", action: { _ in
    ///                     print("This is third action")
    ///                 })
    ///         ]
    ///       self.actionSheet(title: "example actionSheet extension", actions: actionSheetActions)
    ///
    func actionSheet(title: String = "Notification",
                     message: String? = nil,
                     cancelTitle: String? = "Cancel",
                     cancelStyle: UIAlertAction.Style = .cancel,
                     actions: [(title: String, action: ((UIAlertAction) -> Void))]) {

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        actions.forEach {
            alertController.addAction(UIAlertAction(title: $0.title, style: .default, handler: $0.action))
        }

        alertController.addAction(UIAlertAction(title: cancelTitle, style: cancelStyle, handler: { _ in
            alertController.dismiss(animated: true)
        }))

        self.present(alertController, animated: true)
    }
}

extension UIViewController {

    /// This is default indicator for the any view controllers
    /// This positioned center of current view controller
    static let indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)

    /// This is default indicator Label for the any view controllers
    /// This positioned blow of indicator view
    static let indicatorLabel = UILabel(frame: CGRect(x: 0,
                                                      y: 0,
                                                      width: UIScreen.main.bounds.width,
                                                      height: 20))

    /// start default indicator animating
    func startIndicator(labelText: String = "") {
        if UIViewController.indicator.superview == nil {
            UIViewController.indicator.removeFromSuperview()
            UIViewController.indicator.alpha = 0.0
            UIViewController.indicator.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
            UIViewController.indicator.layer.cornerRadius = 10
            UIViewController.indicator.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.7)
            UIViewController.indicator.center = self.view.center
            UIViewController.indicator.clipsToBounds = true
            UIViewController.indicator.startAnimating()
            self.view.addSubview(UIViewController.indicator)
        }

        UIViewController.indicatorLabel.center.x = self.view.center.x
        UIViewController.indicatorLabel.center.y = self.view.center.y + 55
        UIViewController.indicatorLabel.text = labelText
        UIViewController.indicatorLabel.font = UIFont(name: "AppleSDGothicNeo-Light", size: 14.0)
        UIViewController.indicatorLabel.alpha = 0.0
        UIViewController.indicatorLabel.textColor = UIColor.darkText
        UIViewController.indicatorLabel.textAlignment = .center
        UIViewController.indicatorLabel.backgroundColor = UIColor.clear

        if UIViewController.indicatorLabel.superview == nil {
            self.view.addSubview(UIViewController.indicatorLabel)
        }

        UIView.animate(withDuration: 0.2,
                       delay: 0.2,
                       options: UIView.AnimationOptions.curveEaseIn, animations: {
                        UIViewController.indicator.alpha = 1.0
                        UIViewController.indicatorLabel.alpha = 1.0
        })
    }

    /// stop default indicator animating
    func stopIndicator() {
        UIView.animate(withDuration: 0.2,
                       delay: 0.2,
                       options: UIView.AnimationOptions.curveEaseOut, animations: {
                        UIViewController.indicator.alpha = 0.0
                        UIViewController.indicatorLabel.alpha = 0.0
        }, completion: { _ in
            UIViewController.indicator.stopAnimating()
            UIViewController.indicator.removeFromSuperview()
            UIViewController.indicatorLabel.removeFromSuperview()
        })
    }
}
