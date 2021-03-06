//
//  MainViewController.swift
//  tracking-selfie
//
//  Created by 조중윤 on 2022/03/14.
//

import UIKit
import AVFoundation
import Photos
import Vision
import CoreML

enum CameraAccessError: String, Error {
    case isDenied = "Access to camera is denied"
    case isRestricted = "Access to camera is restricted"
}

class MainViewController: UIViewController {
    //MARK: - Properties
    private var vm: (LocalPhotoLibraryUsable & DogPicDownloadable)!
    
    private let captureSession = AVCaptureSession()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var drawings: [CAShapeLayer] = []
    private let photoDataOutput = AVCapturePhotoOutput()
    
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
    
    private let dogPicButton: UIButton = {
        let button = UIButton()
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 15
        button.backgroundColor = .white
        let image = UIImage(systemName: "photo.artframe", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .light))
        button.setImage(image, for: .normal)
        button.tintColor = .systemBlue
        return button
    }()
    
    private let dogPicImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        imageView.backgroundColor = .white.withAlphaComponent(0.5)
        return imageView
    }()
    //MARK: - Callbacks
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addCameraInput()
        self.configureButtons()
        self.configureDogImageView()
        
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
    
    ///Next we need to adapt the preview layer’s frame when the container’s view frame changes; it can potentially change at different points of the UIViewController instance lifecycle
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = CGRect(x: self.view.frame.minX,
                                         y: self.view.frame.minY,
                                         width: self.view.frame.width,
                                         height: self.view.frame.height)
        
        self.view.bringSubviewToFront(shootButton)
        self.view.bringSubviewToFront(dogPicButton)
        self.view.bringSubviewToFront(dogPicImageView)
    }

    //MARK: - Methods
    public func inject(vm: LocalPhotoLibraryUsable & DogPicDownloadable) {
        self.vm = vm
    }
    
    private func configureDogImageView() {
        self.view.addSubview(self.dogPicImageView)
        
        NSLayoutConstraint.activate([
            self.dogPicImageView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            self.dogPicImageView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -20),
            self.dogPicImageView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.5),
            self.dogPicImageView.heightAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.5)
        ])
    }
    
    private func configureButtons() {
        let buttonSize = CGFloat(44)
        
        self.shootButton.frame = CGRect(x: view.frame.size.width - buttonSize * 1.4, y: view.frame.height - buttonSize * 3, width: buttonSize, height: buttonSize)
        self.dogPicButton.frame = CGRect(x: view.frame.size.width - buttonSize * 1.4, y: view.frame.height - buttonSize * 4.5, width: buttonSize, height: buttonSize)
        
        self.view.addSubview(self.shootButton)
        self.view.addSubview(self.dogPicButton)
        
        self.shootButton.isHidden = true
        
        self.shootButton.addTarget(self, action: #selector(shootCurrentFace), for: .touchUpInside)
        self.dogPicButton.addTarget(self, action: #selector(showDogPic), for: .touchUpInside)
    }
    
    @objc private func showDogPic() {
        self.vm.getRandomDogPic { image in
            DispatchQueue.main.async {
                self.dogPicImageView.image = image
                self.presentToastMessage(with: "You're not smiling, Here is a dog picture for you :)")
            }
        }
    }
    
    @objc private func shootCurrentFace() {
        let photoSettings = AVCapturePhotoSettings()
        
        if let photoPreviewType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoPreviewType]
            self.photoDataOutput.capturePhoto(with: photoSettings, delegate: self)
        }
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
        self.previewLayer.frame = CGRect(x: self.view.frame.minX,
                                         y: self.view.frame.minY,
                                         width: self.view.frame.width,
                                         height: self.view.frame.height)
        
        self.view.bringSubviewToFront(shootButton)
        self.view.bringSubviewToFront(dogPicButton)
        self.view.bringSubviewToFront(dogPicImageView)
    }
    
    private func getCameraFrames() {
        //The only key currently supported is the kCVPixelBufferPixelFormatTypeKey key.
        self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
        
        // adding outputs to the capture session
        self.captureSession.addOutput(self.videoDataOutput)
        self.captureSession.addOutput(self.photoDataOutput)
        
        guard let connection = self.videoDataOutput.connection(with: AVMediaType.video),
            connection.isVideoOrientationSupported else { return }
        connection.videoOrientation = .portrait
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
            
            // bounding box related
            let faceBoundingBoxOnScreen = self.previewLayer.layerRectConverted(fromMetadataOutputRect: observedFace.boundingBox)
            let faceBoundingBoxPath = CGPath(rect: faceBoundingBoxOnScreen, transform: nil)
            let faceBoundingBoxShape = CAShapeLayer()
            faceBoundingBoxShape.path = faceBoundingBoxPath
            faceBoundingBoxShape.fillColor = UIColor.clear.cgColor
            faceBoundingBoxShape.strokeColor = UIColor.black.cgColor
            
            var newDrawings = [CAShapeLayer]()
            newDrawings.append(faceBoundingBoxShape)
            
            // face feature related
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

extension MainViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
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

extension MainViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error = error {
                print("error occure : \(error.localizedDescription)")
            }
        
        guard let imageData = photo.fileDataRepresentation() else { return }
        guard let previewImage = UIImage(data: imageData) else { return }
        
        let photoPreviewContainer = PhotoPreviewViewController()
        photoPreviewContainer.inject(previewImage, vm: self.vm)
        self.navigationController?.pushViewController(photoPreviewContainer, animated: true)
    }
}
