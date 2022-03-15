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
    
}

    

