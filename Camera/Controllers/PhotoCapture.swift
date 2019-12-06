//
//  PhotoCapture.swift
//  Camera
//
//  Created by WON on 07/10/2018.
//  Copyright © 2018 WON. All rights reserved.
//

import AVFoundation
import MobileCoreServices
import UIKit

class PhotoCapture: NSObject, PhotoCapturable {

    let filterRenderers: [FilterRenderable?] = [nil] + renderers
    var filterIndex = 0
    var videoFilter: FilterRenderable? {
        return filterRenderers[filterIndex]
    }

    func changeFilter(with swipeDirection: UISwipeGestureRecognizer.Direction) -> Int {
        if swipeDirection == .left {
            filterIndex = (filterIndex + 1) % filterRenderers.count
        } else if swipeDirection == .right {
            filterIndex = (filterIndex + filterRenderers.count - 1) % filterRenderers.count
        }

        return filterIndex
    }

    var captureSession = AVCaptureSession()
    var videoDataOutput = AVCaptureVideoDataOutput()
    private var photoOutput = AVCapturePhotoOutput()
    var captureOutput: AVCaptureOutput {
        return photoOutput
    }

    var captureDeviceInput: AVCaptureDeviceInput?
    var captureDevice: AVCaptureDevice? {
        return captureDeviceInput?.device
    }

    var flashMode: AVCaptureDevice.FlashMode = .off

    /// AVVideoCodecKey, flashMode, highResolution
    var capturePhotoSettings: AVCapturePhotoSettings {
        let photoSettings = AVCapturePhotoSettings(format: [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)])
        if let captureDeviceInput = captureDeviceInput, captureDeviceInput.device.isFlashAvailable {

            if photoOutput.supportedFlashModes.contains(flashMode) {
                photoSettings.flashMode = flashMode
            }
        }

        return photoSettings
    }

    var previewView: PreviewMetalView?
    var sessionQueue = DispatchQueue(label: "camera-cam-serial-queue", qos: .background)
    private let processingQueue = DispatchQueue(label: "photo processing queue", autoreleaseFrequency: .workItem)
    var photoOutputBlock: ((Data) -> Void)?

    func setupSession(with preview: PreviewMetalView, completion: (() -> Void)? = nil) {
        previewView = preview

        guard let device = AVCaptureDevice.defaultVideoDevice else {
            return
        }

        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        addVideoInput(device: device)
        addVideoDataOutput(videoDataOutput: videoDataOutput)
        addPhotoOutput(photoOutput: photoOutput)
        captureSession.commitConfiguration()

        photoOutput.setPreparedPhotoSettingsArray([capturePhotoSettings])
        startRunning()
        completion?()
    }

    func startRunning() {
        guard !captureSession.isRunning else { return }
        sessionQueue.async { [weak self] in
            guard
                let `self` = self,
                let previewView = self.previewView,
                let videoInput = self.captureDeviceInput else {
                    return
            }

            let interfaceOrientation = UIInterfaceOrientation.portrait
            if let photoOrientation = AVCaptureVideoOrientation(interfaceOrientation: interfaceOrientation) {
                if let unwrappedPhotoOutputConnection = self.photoOutput.connection(with: .video) {
                    unwrappedPhotoOutputConnection.videoOrientation = photoOrientation
                }
            }

            let videoDevicePosition = videoInput.device.position
            previewView.mirroring = (videoDevicePosition == .front)
            self.captureSession.startRunning()
        }
    }

    func stopRunning() {
        guard captureSession.isRunning else { return }
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }

    func toggleFlash() {
        flashMode = flashMode.next
    }

    func flipCamera() {
        captureSession.resetInputs()
        guard let toggledDevice = captureDevice?.toggledDevice else { return }
        addVideoInput(device: toggledDevice)
        previewView?.mirroring = toggledDevice.position == .front
    }

    func capture(completion: ((Data) -> Void)?) {
        sessionQueue.async { [weak self] in
            guard let `self` = self else { return }
            self.photoOutputBlock = completion
            self.photoOutput.capturePhoto(with: self.capturePhotoSettings, delegate: self)
        }
    }

    /// Add Video Input
    private func addVideoInput(device: AVCaptureDevice) {
        captureDeviceInput = try? AVCaptureDeviceInput(device: device)
        guard let deviceInput = captureDeviceInput, captureSession.canAddInput(deviceInput) else {
            return
        }
        captureSession.addInput(deviceInput)
    }

    /// Add Video Data Output
    private func addVideoDataOutput(videoDataOutput: AVCaptureVideoDataOutput) {
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            videoDataOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        }
    }

    /// Add Photo Output
    private func addPhotoOutput(photoOutput: AVCapturePhotoOutput) {
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        }
    }

    func changeISO(value: Float) {
        do {
            try captureDevice?.lockForConfiguration()
            defer { captureDevice?.unlockForConfiguration() }
            captureDevice?.setExposureModeCustom(duration: AVCaptureDevice.currentExposureDuration, iso: value)
        } catch {
            print(error)
        }
    }

    func zoom(by factorValue: Float) {
        do {
            try captureDevice?.lockForConfiguration()
            defer { captureDevice?.unlockForConfiguration() }
            captureDevice?.ramp(toVideoZoomFactor: CGFloat(factorValue), withRate: 5.0)
        } catch {
            print(error)
        }
    }

    func focus(with focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {

        sessionQueue.async {
            guard let videoDevice = self.captureDeviceInput?.device else {
                return
            }

            do {
                try videoDevice.lockForConfiguration()
                if videoDevice.isFocusPointOfInterestSupported && videoDevice.isFocusModeSupported(focusMode) {
                    videoDevice.focusPointOfInterest = devicePoint
                    videoDevice.focusMode = focusMode
                }

                if videoDevice.isExposurePointOfInterestSupported && videoDevice.isExposureModeSupported(exposureMode) {
                    videoDevice.exposurePointOfInterest = devicePoint
                    videoDevice.exposureMode = exposureMode
                }

                videoDevice.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                videoDevice.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension PhotoCapture: AVCapturePhotoCaptureDelegate {

    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        AudioServicesDisposeSystemSoundID(1108)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        AudioServicesDisposeSystemSoundID(1108)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let photoPixelBuffer = photo.pixelBuffer else {
            print("Error occurred while capturing photo: Missing pixel buffer (\(String(describing: error)))")
            return
        }

        var photoFormatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: photoPixelBuffer, formatDescriptionOut: &photoFormatDescription)

        processingQueue.async { [weak self] in

            if let filter = self?.videoFilter {
                let sourceImage = CIImage(cvImageBuffer: photoPixelBuffer)
                guard let filteredImage = filter.filter(sourceImage) else {
                    print("CIFilter failed to render image")
                    return
                }

                let metadataAttachments: CFDictionary = photo.metadata as CFDictionary
                guard let data = self?.jpegData(with: filteredImage, attachments: metadataAttachments) else {
                    print("Unable to create JPEG photo")
                    return
                }
                self?.photoOutputBlock?(data)
            } else {
                self?.photoOutputBlock?(photo.fileDataRepresentation()!)
            }
        }
    }

    func jpegData(withPixelBuffer pixelBuffer: CVPixelBuffer, attachments: CFDictionary?) -> Data? {
        let ciContext = CIContext()
        let renderedCIImage = CIImage(cvImageBuffer: pixelBuffer)
        guard let renderedCGImage = ciContext.createCGImage(renderedCIImage, from: renderedCIImage.extent) else {
            print("Failed to create CGImage")
            return nil
        }

        guard let data = CFDataCreateMutable(kCFAllocatorDefault, 0) else {
            print("Create CFData error!")
            return nil
        }

        guard let cgImageDestination = CGImageDestinationCreateWithData(data, kUTTypeJPEG, 1, nil) else {
            print("Create CGImageDestination error!")
            return nil
        }

        CGImageDestinationAddImage(cgImageDestination, renderedCGImage, attachments)
        if CGImageDestinationFinalize(cgImageDestination) {
            return data as Data
        }
        print("Finalizing CGImageDestination error!")
        return nil
    }

    func jpegData(with ciImage: CIImage, attachments: CFDictionary?) -> Data? {
        let ciContext = CIContext()
        guard let renderedCGImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            print("Failed to create CGImage")
            return nil
        }

        guard let data = CFDataCreateMutable(kCFAllocatorDefault, 0) else {
            print("Create CFData error!")
            return nil
        }

        guard let cgImageDestination = CGImageDestinationCreateWithData(data, kUTTypeJPEG, 1, nil) else {
            print("Create CGImageDestination error!")
            return nil
        }

        CGImageDestinationAddImage(cgImageDestination, renderedCGImage, attachments)
        if CGImageDestinationFinalize(cgImageDestination) {
            return data as Data
        }
        print("Finalizing CGImageDestination error!")
        return nil

    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension PhotoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        processVideo(sampleBuffer: sampleBuffer)
    }

    func processVideo(sampleBuffer: CMSampleBuffer) {
        guard let videoPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
                return
        }
        var finalVideoPixelBuffer = videoPixelBuffer
        if let filter = videoFilter {
            if !filter.isPrepared {
                filter.prepare(with: formatDescription, outputRetainedBufferCountHint: 3)
            }

            // Send the pixel buffer through the filter
            guard let filteredBuffer = filter.render(pixelBuffer: finalVideoPixelBuffer) else {
                print("Unable to filter video buffer")
                return
            }

            finalVideoPixelBuffer = filteredBuffer
        }
        /// Rendering here
        previewView?.pixelBuffer = finalVideoPixelBuffer
    }
}
