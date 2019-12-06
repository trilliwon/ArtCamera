//
//  UILabelExtensions.swift
//  Camera
//
//  Created by WON on 27/09/2018.
//  Copyright © 2018 WON. All rights reserved.
//

import UIKit

extension UILabel {

    func makeSubStringColored(subString: String, color: UIColor) {
        self.attributedText = (self.text ?? "")
            .colored(range: ((self.text ?? "") as NSString)
                .range(of: subString), color: color)
    }

    func makeSubStringColored(range: (location: Int, length: Int), color: UIColor) {
        self.attributedText = (self.text ?? "")
            .colored(range: NSRange(location: range.location, length: range.length), color: color)
    }
}
