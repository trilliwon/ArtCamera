//
//  PermissionCheckable.swift
//  Camera
//
//  Created by WON on 07/10/2018.
//  Copyright © 2018 WON. All rights reserved.
//

import AVFoundation
import Photos
import UIKit

protocol PermissionCheckable {
    func doAfterVideoPermission(workItem: ((Bool) -> Void)?)
    func doAfterPhotoPermission(workItem: ((Bool) -> Void)?)
}

extension PermissionCheckable where Self: UIViewController {
    
    func doAfterVideoPermission(workItem: ((Bool) -> Void)?) {
        checkForVideo { hasPermission in
            workItem?(hasPermission)
        }
    }
    
    func doAfterPhotoPermission(workItem: ((Bool) -> Void)?) {
        checkForPhotoLibrary { hasPermission in
            workItem?(hasPermission)
        }
    }
    
    private func checkForVideo(completion: ((Bool) -> Void)?) {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            completion?(true)
        case .restricted:
            alert(message: "Video Permission Restriced", okTitle: "Ok") {
                completion?(false)
            }
        case .denied:
            alert(message: "Video Permission Denied", okTitle: "Ok") {
                completion?(false)
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion?(granted)
                }
            }
        @unknown default:
            fatalError()
        }
    }
    
    private func checkForPhotoLibrary(completion: ((Bool) -> Void)?) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            completion?(true)
        case .restricted:
            alert(message: "Video Permission Denied", okTitle: "Ok") {
                completion?(false)
            }
        case .denied:
            alert(message: "Video Permission Denied", okTitle: "Ok") {
                completion?(false)
            }
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                if status != .authorized {
                    self?.checkForPhotoLibrary(completion: completion)
                } else {
                    DispatchQueue.main.async {
                        completion?(true)
                    }
                }
            }
        @unknown default:
            fatalError()
            
        }
    }
}
