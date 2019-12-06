//
//  NotificationExtensions.swift
//  Camera
//
//  Created by WON on 27/09/2018.
//  Copyright © 2018 WON. All rights reserved.
//

import UIKit

extension Notification {

    var keyboardHeight: CGFloat? {
        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height
    }
}
