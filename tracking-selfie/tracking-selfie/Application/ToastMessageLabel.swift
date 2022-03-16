//
//  ToastMessageLabel.swift
//  tracking-selfie
//
//  Created by 조중윤 on 2022/03/16.
//

import UIKit

class ToastMessageLabel: UILabel {
    var contentInsets = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10)

    override func drawText(in rect: CGRect) {
        let insetRect = rect.inset(by: contentInsets)
        super.drawText(in: insetRect)
    }
    
    override var intrinsicContentSize: CGSize {
        return addInsets(to: super.intrinsicContentSize)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return addInsets(to: super.sizeThatFits(size))
    }
    
    private func addInsets(to size: CGSize) -> CGSize {
        let width = size.width + contentInsets.left + contentInsets.right
        let height = size.height + contentInsets.top + contentInsets.bottom
        return CGSize(width: width, height: height)
    }
    
}


