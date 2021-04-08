//
//  CAMViewController.swift
//  Camera
//
//  Created by WON on 26/09/2018.
//  Copyright © 2018 WON. All rights reserved.
//

import AVFoundation
import Photos
import UIKit

class CamViewController: UIViewController {

    @IBOutlet private weak var topToolView: UIStackView!
    @IBOutlet private weak var bottomToolView: UIView!
    // MARK: - Properties
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium) // .light, .medium, .heavy
    private let selectioNFeedback = UISelectionFeedbackGenerator()

    private var gridMode = GridMode.on {
        didSet {
            gridMode == .on ? preview.showGridView() : preview.hideGridView()
            gridButton.setImage(gridMode.icon, for: .normal)
            gridButton.layoutIfNeeded()
        }
    }

    @IBOutlet private weak var thumbnailImageView: UIImageView!
    @IBOutlet private weak var gridButton: UIButton! {
        didSet {
            // ios-grid, ionicons
            gridButton.setImage(gridMode.icon, for: .normal)
        }
    }

    @IBOutlet private weak var flashModeButton: UIButton! {
        didSet {
            flashModeButton.setImage(photoCapture.flashMode.icon, for: .normal)
        }
    }

    @IBOutlet private weak var flipCameraButton: UIButton!
    @IBOutlet private weak var shootButton: ShooterButton!
    @IBOutlet private weak var preview: PreviewMetalView!

    private let focusView = FocusView()
    private let photoCapture = PhotoCapture()

    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(focusView)

        checkForVideo { [unowned self] result in
            self.photoCapture.setupSession(with: self.preview)
        }

        thumbnailImageView.isUserInteractionEnabled = true
        thumbnailImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openDetailView)))
        view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(pinch(_:))))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        photoCapture.startRunning()
        let initialThermalState = ProcessInfo.processInfo.thermalState
        if initialThermalState == .serious || initialThermalState == .critical {
            DispatchQueue.main.async { [weak self] in
                self?.alert(message: "Thermal state: \(initialThermalState.description)")
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        photoCapture.stopRunning()
    }

    // MARK: status bar
    override var prefersStatusBarHidden: Bool {
        return true
    }

    @objc
    func openDetailView() {
        if
            let detailImageView = ImageDetailViewController.instance as? ImageDetailViewController ,
            let image = thumbnailImageView.image {
            detailImageView.image = image
            detailImageView.modalPresentationStyle = .fullScreen
            present(detailImageView, animated: true)
        }
    }

    // MARK: - IBActions
    @IBAction private func shootButtonTapped(_ sender: ShooterButton) {
        impactFeedback.impactOccurred()
        DispatchQueue.main.async { [weak self] in
            if let self = self {
                self.preview.layer.opacity = 0
                UIView.animate(withDuration: 0.25) {
                    self.preview.layer.opacity = 1
                }
            }
        }

        photoCapture.capture { photoData in
            DispatchQueue.main.async {
                UIView.transition(with: self.thumbnailImageView,
                                  duration: 0.3,
                                  options: .transitionCrossDissolve,
                                  animations: {
                                    self.thumbnailImageView.image = UIImage(data: photoData)
                })
            }
            PHPhotoLibrary.shared().performChanges({
                let options = PHAssetResourceCreationOptions()
                let creationRequest = PHAssetCreationRequest.forAsset()
                options.uniformTypeIdentifier = self.photoCapture.capturePhotoSettings
                    .processedFileType.map { $0.rawValue }
                creationRequest.addResource(with: .photo, data: photoData, options: options)
            }, completionHandler: { success, error in
                Log.print(success, error ?? "")
            })
        }
    }

    @IBAction private func focusAndExposeTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: preview)
        let texturePoint = location

        if bottomToolView.frame.contains(location) || topToolView.frame.contains(location) {
            return
        }

        focusView.focus(point: location) {
            self.focusView.isHidden = true
        }
        let textureRect = CGRect(origin: texturePoint, size: .zero)
        let deviceRect = photoCapture.videoDataOutput.metadataOutputRectConverted(fromOutputRect: textureRect)
        photoCapture.focus(with: .autoFocus, exposureMode: .autoExpose, at: deviceRect.origin, monitorSubjectAreaChange: true)
    }

    @IBAction private func changeFilterSwipe(_ gesture: UISwipeGestureRecognizer) {
        let newIndex = photoCapture.changeFilter(with: gesture.direction)
        let filterDescription = photoCapture.filterRenderers[newIndex]?.description ?? "None"
        updateFilterLabel(description: filterDescription)
        selectioNFeedback.selectionChanged()
    }

    @IBOutlet private weak var filterLabel: UILabel!

    private func updateFilterLabel(description: String) {
        filterLabel.text = description
        filterLabel.sizeToFit()
        filterLabel.alpha = 0.0
        filterLabel.isHidden = false

        // Fade in
        UIView.animate(withDuration: 0.25) {
            self.filterLabel.alpha = 1.0
        }

        // Fade out
        UIView.animate(withDuration: 3.0) {
            self.filterLabel.alpha = 0.0
        }
    }
    @IBAction private func gridButtonTapped(_ sender: UIButton) {
        gridMode.toggle()
    }

    @IBAction private func flipButtonTapped(_ sender: UIButton) {
        photoCapture.flipCamera()
        UIView.transition(with: preview, duration: 0.3, options: .transitionFlipFromRight, animations: nil, completion: { [weak self] _ in
            guard let `self` = self else { return }
            self.focusView.focus(point: self.view.center) {
                self.focusView.isHidden = true
            }
        })
    }

    @IBAction private func flashModeButtonTapped(_ sender: UIButton) {
        photoCapture.toggleFlash()
        flashModeButton.setImage(photoCapture.flashMode.icon, for: .normal)
    }

    var lastZoomFactor: CGFloat = 1.0

    @objc
    func pinch(_ pinch: UIPinchGestureRecognizer) {

        guard let device = photoCapture.captureDevice else { return }

        // Return zoom value between the minimum and maximum zoom values
        func minMaxZoom(_ factor: CGFloat) -> CGFloat {
            return min(min(max(factor, 1.0), 3.0), device.activeFormat.videoMaxZoomFactor)
        }

        let newScaleFactor = minMaxZoom(pinch.scale * lastZoomFactor)

        switch pinch.state {
        case .began: fallthrough
        case .changed: photoCapture.zoom(by: Float(newScaleFactor))
        case .ended:
            lastZoomFactor = minMaxZoom(newScaleFactor)
            photoCapture.zoom(by: Float(lastZoomFactor))
        default:
            break
        }
    }

    private func checkForVideo(completion: ((Bool) -> Void)?) {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        if case .authorized = status {
            completion?(true)
        } else {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion?(granted)
                }
            }
        }
    }

    private func checkForPhotoLibrary(completion: ((Bool) -> Void)?) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            completion?(true)
        case .limited:
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
