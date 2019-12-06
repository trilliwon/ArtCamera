//
//  UIImage+Extensions.swift
//  Camera
//
//  Created by WON on 07/10/2018.
//  Copyright © 2018 WON. All rights reserved.
//

import UIKit

internal extension UIImage {

    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
