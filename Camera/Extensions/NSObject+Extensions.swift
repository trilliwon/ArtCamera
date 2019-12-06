//
//  NSObject+Extensions.swift
//  coffee-camera
//
//  Created by wonjo on 23/05/2018.
//  Copyright © 2018 trilliwon. All rights reserved.
//

import Foundation

extension NSObject {

    class var className: String {
        return String(describing: self)
    }

    var className: String {
        return type(of: self).className
    }
}
