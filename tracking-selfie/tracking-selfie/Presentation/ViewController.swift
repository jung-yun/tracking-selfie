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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.verifyAccessToCamera()
    }
    
    private func verifyAccessToCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // to do
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    // to do
                }
            }
        case .denied:
            // to do
            return
        case .restricted:
            // todo
            return
        @unknown default:
            assertionFailure("ERROR: something went wrong verifying access to camera")
        }
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

