//
//  AVCaptureDevice+Extensions.swift
//  coffee-camera
//
//  Created by wonjo on 05/06/2018.
//  Copyright © 2018 trilliwon. All rights reserved.
//

import AVFoundation
import Photos
import UIKit

extension AVCaptureDevice {

    static var defaultVideoDevice: AVCaptureDevice? {
        // Choose the back dual camera if available, otherwise default to a wide angle camera.
        if let dualCameraDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInDualCamera,
                                                          for: AVMediaType.video, position: .back) {
            return dualCameraDevice
        } else if let backCameraDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                                                                 for: AVMediaType.video, position: .back) {
            // If the back dual camera is not available, default to the back wide angle camera.
            return backCameraDevice
        } else if let frontCameraDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                                                                  for: AVMediaType.video, position: .front) {
            return frontCameraDevice
        }

        return nil
    }
}

extension AVCaptureDevice.DiscoverySession {

    var uniqueDevicePositionsCount: Int {
        var uniqueDevicePositions: [AVCaptureDevice.Position] = []

        for device in devices {
            if !uniqueDevicePositions.contains(device.position) {
                uniqueDevicePositions.append(device.position)
            }
        }

        return uniqueDevicePositions.count
    }
}

extension AVCaptureVideoOrientation {
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        default: return nil
        }
    }

    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }
}
