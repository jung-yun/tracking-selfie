//
//  ViewController.swift
//  tracking-selfie
//
//  Created by 조중윤 on 2022/03/14.
//

import UIKit
import AVFoundation
import Photos

class ViewController: UIViewController {
    private let captureSession = AVCaptureSession()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addCameraInput()
        self.verifyAccessToCamera()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = self.view.frame
    }

    private func verifyAccessToCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.showCameraFeed()
            self.captureSession.startRunning()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.showCameraFeed()
                    self.captureSession.startRunning()
                }
            }
        case .denied:
            // UI update without permission
            return
        case .restricted:
            // UI update without permission
            return
        @unknown default:
            assertionFailure("ERROR: something went wrong verifying access to camera")
        }
    }
    
    private func showCameraFeed() {
        DispatchQueue.main.sync {
            self.previewLayer.videoGravity = .resizeAspectFill
            self.view.layer.addSublayer(self.previewLayer)
            self.previewLayer.frame = self.view.frame
            self.view.setNeedsLayout()
        }
    }
    
    private func addCameraInput() {
        guard let device = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera,
                          .builtInDualCamera,
                          .builtInTrueDepthCamera],
            mediaType: .video,
            position: .front).devices.first else {
               fatalError("No back camera device found, please make sure to run SimpleLaneDetection in an iOS device and not a simulator")
        }
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        self.captureSession.addInput(cameraInput)
    }
    
    private func verifyAccessToPhotoLibraryAddition() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            switch status {
            case .notDetermined:
                // The user hasn't determined this app's access.
                return
            case .restricted:
                // The system restricted this app's access.
                return
            case .denied:
                // The user explicitly denied this app's access.
                return
            case .authorized:
                // The user authorized this app to access Photos data.
                return
            case .limited:
                // The user authorized this app for limited Photos access.
                return
            @unknown default:
                assertionFailure("ERROR: something went wrong verifying access to photo library addition")
            }
        }
    }
    
}
