//
//  StringExtensions.swift
//  Camera
//
//  Created by WON on 27/09/2018.
//  Copyright © 2018 WON. All rights reserved.
//

import Foundation
import UIKit

extension String {

    func makeRange(from startIndex: Int, to endIndex: Int) -> Range<String.Index>? {
        if startIndex > endIndex { return nil }
        if self.count < endIndex { return nil }
        return self.index(self.startIndex, offsetBy: startIndex)..<self.index(self.startIndex, offsetBy: endIndex)
    }

    var date: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: String(self.prefix(10)))
    }

    var localized: String {
        return NSLocalizedString(self, comment: "")
    }

    func colored(range: NSRange, color: UIColor = UIColor.default) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self)
        let attribute = [NSAttributedString.Key.foregroundColor: color, NSAttributedString.Key.backgroundColor: .clear]
        attributedString.addAttributes(attribute, range: range)
        return attributedString
    }

    func underLined(substring: String? = nil) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self)

        let attribute: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: UIColor.default,
            NSAttributedString.Key.backgroundColor: UIColor.clear,
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
        ]

        attributedString
            .addAttributes(attribute, range: (self as NSString)
            .range(of: substring ?? self))
        return attributedString
    }
}
