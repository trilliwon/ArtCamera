//
//  AVCaptureSession+Extensions.swift
//  Camera
//
//  Created by WON on 07/10/2018.
//  Copyright © 2018 WON. All rights reserved.
//

import AVFoundation

extension AVCaptureSession {
    func resetInputs() {
        // remove all sesison inputs
        for input in inputs {
            removeInput(input)
        }
    }
}
