//
//  PhotoCapturable.swift
//  Camera
//
//  Created by WON on 10/10/2018.
//  Copyright © 2018 WON. All rights reserved.
//

import AVFoundation
import PhotosUI

extension AVCaptureDevice.FlashMode {

    var icon: UIImage? {
        switch self {
        case .on:
            return UIImage(named: "ic_flash_on")
        case .off:
            return UIImage(named: "ic_flash_off")
        case .auto:
            return UIImage(named: "ic_flash_auto")
        @unknown default:
            return UIImage(named: "ic_flash_off")
        }
    }

    var next: AVCaptureDevice.FlashMode {
        switch self {
        case .on:
            return .off
        case .off:
            return .auto
        case .auto:
            return .on
        @unknown default:
            return .off
        }
    }
}

enum HDRMode {
    case on
    case auto
    case off

    var icon: UIImage {
        switch self {
        case .auto:
            return UIImage()
        case .on:
            return UIImage()
        case .off:
            return UIImage()
        }
    }
}

enum GridMode {
    case on
    case off
}

enum LivePhotoMode {
    case on
    case off
}

extension GridMode {
    var icon: UIImage? {
        switch self {
        case .on:
            return UIImage(named: "ic_grid_on")
        case .off:
            return UIImage(named: "ic_grid_off")
        }
    }

    mutating func toggle() {
        self = self == .on ? .off : .on
    }
}

extension LivePhotoMode {

    mutating func toggle() {
        self = self == .on ? .off : .on
    }

    var icon: UIImage {
        switch self {
        case .on:
            return PHLivePhotoView.livePhotoBadgeImage(options: PHLivePhotoBadgeOptions.overContent)
        case .off:
            return PHLivePhotoView.livePhotoBadgeImage(options: PHLivePhotoBadgeOptions.liveOff)
        }
    }
}

protocol PhotoCapturable {

    var captureSession: AVCaptureSession { get }
    var captureOutput: AVCaptureOutput { get }
    var captureDeviceInput: AVCaptureDeviceInput? { get set }
    var captureDevice: AVCaptureDevice? { get }
    var capturePhotoSettings: AVCapturePhotoSettings { get }
    var previewView: PreviewMetalView? { get set }
    var sessionQueue: DispatchQueue { get }

    func setupSession(with preview: PreviewMetalView, completion: (() -> Void)?)
    func stopRunning()
    func startRunning()
    func toggleFlash()
    func flipCamera()
    func capture(completion: ((Data) -> Void)?)
}
