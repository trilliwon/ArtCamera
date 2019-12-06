//
//  AVCaptureDevice+Extensions.swift
//  Camera
//
//  Created by WON on 07/10/2018.
//  Copyright © 2018 WON. All rights reserved.
//

import AVFoundation

extension AVCaptureDevice {

    var toggledPosition: AVCaptureDevice.Position {
        return self.position == .front ? .back : .front
    }

    var toggledDevice: AVCaptureDevice? {
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera,
                                                              .builtInTelephotoCamera,
                                                              .builtInTrueDepthCamera,
                                                              .builtInWideAngleCamera],
                                                mediaType: .video,
                                                position: position == .front ? .back : .front).devices.first
    }

    func tryToggleTorch() {

        guard hasFlash else {
            return
        }

        do {
            try lockForConfiguration()
            switch torchMode {
            case .auto:
                torchMode = .on
            case .on:
                torchMode = .off
            case .off:
                torchMode = .auto
            @unknown default:
                fatalError()
            }
            unlockForConfiguration()
        } catch _ { }
    }
}
