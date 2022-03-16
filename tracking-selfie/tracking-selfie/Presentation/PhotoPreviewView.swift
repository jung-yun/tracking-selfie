//
//  PhotoPreviewView.swift
//  tracking-selfie
//
//  Created by 조중윤 on 2022/03/15.
//

import UIKit
import Vision
import Photos

class PhotoPreviewViewController: UIViewController {
    private var photoImageView: UIImageView! = nil
    private var croppedImages: [UIImage] = []
    
    override func viewDidLoad() {
        self.setRightBarButtonItem()
        
        guard let image = photoImageView.image else { return }
        self.configurePhotoImageView(with: image)
        self.detectFace(on: image)
    }
    
    public func injectImage(_ image: UIImage) {
        self.photoImageView.image = image
    }
    
    private func configurePhotoImageView(with image: UIImage) {
        photoImageView = UIImageView(image: image)
        photoImageView.contentMode = .scaleAspectFill
        let scaledHeight = view.frame.width / image.size.width * image.size.height
        
        photoImageView.frame = CGRect(x: 0,
                                      y: 0,
                                      width: self.view.frame.width,
                                      height: scaledHeight)
        self.view.addSubview(photoImageView)
    }
    
    private func detectFace(on image: UIImage) {
        let request = VNDetectFaceRectanglesRequest { req, err in
            if let err = err {
                print(err.localizedDescription)
                return
            }
            
            req.results?.forEach({ [weak self] res in
                guard let faceObservation = res as? VNFaceObservation else { return }
                self?.handleDetectedFace(with: faceObservation)
            })
        }
        
        guard let cgImage = image.cgImage else { return }
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .leftMirrored, options: [:])
        do {
            try handler.perform([request])
        } catch let reqErr {
            print("Failed to perform reqeust", reqErr)
        }
    }
    
    private func handleDetectedFace(with faceObservation: VNFaceObservation) {
        let scaledHeight = self.photoImageView.frame.height
        let height = scaledHeight * faceObservation.boundingBox.height
        let width = self.view.frame.width * faceObservation.boundingBox.width
        let y = scaledHeight * (1 - faceObservation.boundingBox.origin.y) - height
        let x = self.view.frame.width * (1 - faceObservation.boundingBox.origin.x) - width
        
        let redView = UIView()
        redView.backgroundColor = .red
        redView.alpha = 0.3
        redView.frame = CGRect(x: x, y: y, width: width, height: height)
        self.view.addSubview(redView)

        self.croppedImages.append(self.getCroppedImageAt(redView: redView))
    }
    
    private func getCroppedImageAt(redView: UIView) -> UIImage {
        let imageSize = photoImageView.image!.size
        let imageViewSize = photoImageView.bounds.size

        var scale : CGFloat = imageViewSize.width / imageSize.width
        if imageSize.height * scale < imageViewSize.height {
            scale = imageViewSize.height / imageSize.height
        }

        let dispSize = CGSize(width: imageViewSize.width/scale, height: imageViewSize.height/scale)
        let dispOrigin = CGPoint(x: (imageSize.width-dispSize.width)/2.0,
                                 y: (imageSize.height-dispSize.height)/2.0)
        
        let r = redView.convert(redView.bounds, to: self.photoImageView)
        let cropRect = CGRect(x: r.origin.x/scale+dispOrigin.x,
                              y: r.origin.y/scale+dispOrigin.y,
                              width: r.width/scale,
                              height: r.height/scale)
        
        let rend = UIGraphicsImageRenderer(size:cropRect.size)
        let croppedImage = rend.image { _ in
            self.photoImageView.image!.draw(at: CGPoint(x:-cropRect.origin.x,
                                                        y:-cropRect.origin.y))
        }
         
        return croppedImage
    }
    
    private func setRightBarButtonItem() {
        let backToMainButton = UIBarButtonItem(barButtonSystemItem: .save,
                                               target: self,
                                               action: #selector(savePhoto))

        navigationItem.rightBarButtonItems = [backToMainButton]
    }
    
    @objc private func savePhoto() {
        PHPhotoLibrary.requestAuthorization { (status) in
            if status == .authorized {
                do {
                    for croppedImage in self.croppedImages {
                        try PHPhotoLibrary.shared().performChangesAndWait {
                            PHAssetChangeRequest.creationRequestForAsset(from: croppedImage)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.navigationController?.popViewController(animated: true)
                    }

                } catch {
                    assertionFailure(error.localizedDescription)
                }
            } else {
                self.presentAlert(title: "ERROR", message: "Cannot Access To Photo Library",
                                  confirmTitle: "OK", confirmHandler: nil,
                                  cancelTitle: nil, cancelHandler: nil,
                                  completion: nil, autodismiss: nil)
            }
        }
    }

}

