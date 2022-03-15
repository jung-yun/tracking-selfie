//
//  ViewController.swift
//  tracking-selfie
//
//  Created by 조중윤 on 2022/03/14.
//

import UIKit
import AVFoundation
import Photos
import Vision

enum CameraAccessError: String, Error {
    case isDenied = "Access to camera is denied"
    case isRestricted = "Access to camera is restricted"
}

class ViewController: UIViewController {
    private let captureSession = AVCaptureSession()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var drawings: [CAShapeLayer] = []
    
    private let shootButton: UIButton = {
        let button = UIButton()
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 15
        button.backgroundColor = .white
        let image = UIImage(systemName: "camera", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .light))
        button.setImage(image, for: .normal)
        button.tintColor = .systemBlue
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addCameraInput()
        self.configureCameraShootButton()
        self.isAllowedAccessToCamera { result in
            switch result {
            case .success(_):
                self.showCameraFeed()
                self.getCameraFrames()
                self.captureSession.startRunning()
            case .failure(let cameraAccessError):
                self.presentAlert(title: "Camera Access Error",
                                  message: cameraAccessError.rawValue,
                                  confirmTitle: "OK", confirmHandler: nil,
                                  cancelTitle: nil, cancelHandler: nil,
                                  completion: nil, autodismiss: nil)
            }
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = CGRect(x: self.view.frame.minX, y: self.view.frame.minY, width: self.view.frame.width, height: self.view.frame.height * 0.7)
    }

    private func configureCameraShootButton() {
        let buttonSize = CGFloat(44)
        
        self.shootButton.frame = CGRect(x: view.frame.size.width - buttonSize * 1.4, y: view.frame.height - buttonSize * 3.5, width: buttonSize, height: buttonSize)
        
        self.view.addSubview(self.shootButton)
        self.shootButton.isHidden = true
        self.shootButton.addTarget(self, action: #selector(shootCurrentFace), for: .touchUpInside)
    }
    
    @objc private func shootCurrentFace() {
        print("save face to library")
    }
    
    private func addCameraInput() {
        guard let device = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera,
                          .builtInDualCamera,
                          .builtInTrueDepthCamera],
            mediaType: .video,
            position: .front).devices.first else {
                fatalError("No front camera device found, please make sure to run SimpleLaneDetection in an iOS device and not a simulator")
        }
        
        do {
            let cameraInput = try AVCaptureDeviceInput(device: device)
            // adding input to the capture session
            self.captureSession.addInput(cameraInput)
        } catch {
            fatalError(error.localizedDescription)
        }
        
    }
    
    private func isAllowedAccessToCamera(handler: @escaping (Result<Void, CameraAccessError>) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            handler(.success(()))
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    handler(.success(()))
                } else {
                    handler(.failure(.isDenied))
                }
            }
        case .denied:
            handler(.failure(.isDenied))
        case .restricted:
            handler(.failure(.isRestricted))
        @unknown default:
            fatalError("ERROR: something went wrong verifying access to camera")
        }
    }
    
    private func showCameraFeed() {
        self.previewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = CGRect(x: self.view.frame.minX, y: self.view.frame.minY, width: self.view.frame.width, height: self.view.frame.height * 0.7)
        
        self.view.setNeedsLayout()
    }
    
    private func getCameraFrames() {
        self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
        // adding output to the capture session
        self.captureSession.addOutput(self.videoDataOutput)
        guard let connection = self.videoDataOutput.connection(with: AVMediaType.video),
            connection.isVideoOrientationSupported else { return }
        connection.videoOrientation = .portrait
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
    
    private func detectFace(in image: CVPixelBuffer) {
        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
            
            DispatchQueue.main.async {
                if let results = request.results as? [VNFaceObservation], results.count > 0 {
                    self.handleFaceDetectionResults(results)
                    self.shootButton.isHidden = false
                } else {
                    self.clearDrawings()
                    self.shootButton.isHidden = true
                }
            }
        })
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
        try? imageRequestHandler.perform([faceDetectionRequest])
    }
    
    private func handleFaceDetectionResults(_ observedFaces: [VNFaceObservation]) {
        self.clearDrawings()
        
        let facesBoundingBoxes: [CAShapeLayer] = observedFaces.flatMap({ (observedFace: VNFaceObservation) -> [CAShapeLayer] in
            
            let faceBoundingBoxOnScreen = self.previewLayer.layerRectConverted(fromMetadataOutputRect: observedFace.boundingBox)
            let faceBoundingBoxPath = CGPath(rect: faceBoundingBoxOnScreen, transform: nil)
            let faceBoundingBoxShape = CAShapeLayer()
            faceBoundingBoxShape.path = faceBoundingBoxPath
            faceBoundingBoxShape.fillColor = UIColor.clear.cgColor
            faceBoundingBoxShape.strokeColor = UIColor.black.cgColor
            
            var newDrawings = [CAShapeLayer]()
            newDrawings.append(faceBoundingBoxShape)
            
            //drawing facial features
            if let landmarks = observedFace.landmarks {
                newDrawings = newDrawings + self.drawFacicalFeatures(landmarks, screenBoundingBox: faceBoundingBoxOnScreen)
            }
            
            return newDrawings
        })
        
        facesBoundingBoxes.forEach({ faceBoundingBox in self.view.layer.addSublayer(faceBoundingBox) })
        self.drawings = facesBoundingBoxes
    }
    
    private func clearDrawings() {
        self.drawings.forEach({ drawing in drawing.removeFromSuperlayer() })
    }
    
    private func drawFacicalFeatures(_ landmarks: VNFaceLandmarks2D, screenBoundingBox: CGRect) -> [CAShapeLayer] {
        var faceFeaturesDrawings: [CAShapeLayer] = []
        
        if let leftEyebrow = landmarks.leftEyebrow {
            let leftEyebrowDrawing = self.drawFacialFeature(leftEyebrow, screenBoundingBox: screenBoundingBox)
            faceFeaturesDrawings.append(leftEyebrowDrawing)
        }
        
        if let rightEyebrow = landmarks.rightEyebrow {
            let rightEyebrowDrawing = self.drawFacialFeature(rightEyebrow, screenBoundingBox: screenBoundingBox)
            faceFeaturesDrawings.append(rightEyebrowDrawing)
        }
        
        if let leftEye = landmarks.leftEye {
            let eyeDrawing = self.drawFacialFeature(leftEye, screenBoundingBox: screenBoundingBox)
            faceFeaturesDrawings.append(eyeDrawing)
        }
        
        if let rightEye = landmarks.rightEye {
            let eyeDrawing = self.drawFacialFeature(rightEye, screenBoundingBox: screenBoundingBox)
            faceFeaturesDrawings.append(eyeDrawing)
        }
        
        if let nose = landmarks.noseCrest {
            let noseDrawing = self.drawFacialFeature(nose, screenBoundingBox: screenBoundingBox)
            faceFeaturesDrawings.append(noseDrawing)
        }
        
        if let innerLips = landmarks.innerLips {
            let innerLipsDrawing = self.drawFacialFeature(innerLips, screenBoundingBox: screenBoundingBox)
            faceFeaturesDrawings.append(innerLipsDrawing)
        }
        
        if let outerLips = landmarks.outerLips {
            let outerLipsDrawing = self.drawFacialFeature(outerLips, screenBoundingBox: screenBoundingBox)
            faceFeaturesDrawings.append(outerLipsDrawing)
        }
        
        if let faceContour = landmarks.faceContour {
            let faceContourDrawing = self.drawFacialFeature(faceContour, screenBoundingBox: screenBoundingBox)
            faceFeaturesDrawings.append(faceContourDrawing)
        }
        
        if let medianLine = landmarks.medianLine {
            let medianLineDrawing = self.drawFacialFeature(medianLine, screenBoundingBox: screenBoundingBox)
            faceFeaturesDrawings.append(medianLineDrawing)
        }
    
        return faceFeaturesDrawings
    }
    
    private func drawFacialFeature(_ feature: VNFaceLandmarkRegion2D, screenBoundingBox: CGRect) -> CAShapeLayer {
        let featurePath = CGMutablePath()
        let pathPoints = feature.normalizedPoints
            .map({ point in
                CGPoint(
                    // point x, y를 바꿀 시 drawing이 -90도 회전
                    x: point.y * screenBoundingBox.height + screenBoundingBox.origin.x,
                    y: point.x * screenBoundingBox.width + screenBoundingBox.origin.y)
             })
        
        featurePath.addLines(between: pathPoints)
        featurePath.closeSubpath()
        let featureDrawing = CAShapeLayer()
        featureDrawing.path = featurePath
        featureDrawing.fillColor = UIColor.clear.cgColor
        featureDrawing.strokeColor = UIColor.systemRed.cgColor
        
        return featureDrawing
    }
    
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            debugPrint("unable to get image from sample buffer")
            return
        }
            
        self.detectFace(in: frame)
    }
}

