//
//  UIViewController.swift
//  tracking-selfie
//
//  Created by 조중윤 on 2022/03/15.
//

import UIKit

extension UIViewController {
    //MARK: - Alert Controller Method
    typealias AlertActionHandler = ((UIAlertAction) -> Void)
    
    func presentAlert(
        title: String, message: String? = nil,
        confirmTitle: String? = nil, confirmHandler: AlertActionHandler? = nil,
        cancelTitle: String? = nil, cancelHandler: AlertActionHandler? = nil,
        completion: (() -> Void)? = nil, autodismiss: Bool? = false)
        {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if let confirmTitle = confirmTitle {
            let confirmAction = UIAlertAction(title: confirmTitle, style: .default, handler: confirmHandler)
            alert.addAction(confirmAction)
        }
        
        if let cancelTitle = cancelTitle {
            let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: cancelHandler)
            alert.addAction(cancelAction)
        }
        
        self.present(alert, animated: true, completion: completion)
        
        if autodismiss != nil && autodismiss! {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                alert.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    //MARK: - Toast Message Method
    func presentToastMessage(with text: String) {
        let label = ToastMessageLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        let labelHeight = self.view.frame.height / 35
        label.font = UIFont.systemFont(ofSize: labelHeight * 0.6)
        label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        label.textColor = UIColor.white
        label.text = text
        label.layer.cornerRadius = labelHeight / 3
        label.layer.masksToBounds = true
        self.view.addSubview(label)
        
        NSLayoutConstraint.activate(
            [
            label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -self.view.frame.height / 3)
            ]
        )
        
        UIView.animate(withDuration: 3.0, delay: 0.5, options: .curveEaseOut) {
            label.alpha = 0.0
        } completion: { (completion) in
            label.removeFromSuperview()
        }
    }
    
}

    

