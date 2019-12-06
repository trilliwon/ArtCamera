//
//  CIImage+Extensions.swift
//  Camera
//
//  Created by WON on 07/10/2018.
//  Copyright © 2018 WON. All rights reserved.
//

import UIKit

internal extension CIImage {

    func toUIImage() -> UIImage {
        /* If need to reduce the process time, than use next code.
         But ot produce a bug with wrong filling in the simulator.
         return UIImage(ciImage: self)
         */
        let context = CIContext(options: nil)
        let cgImage = context.createCGImage(self, from: self.extent)!
        let image = UIImage(cgImage: cgImage)
        return image
    }

    func toCGImage() -> CGImage? {
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(self, from: self.extent) {
            return cgImage
        }
        return nil
    }
}
