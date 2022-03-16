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
    private var previewImage: UIImage? = nil
    private var croppedImages: [UIImage] = []
    private var redViews: [UIView] = []
    private var photoImageView: UIImageView! = nil
    
    override func viewDidLoad() {
        self.setRightBarButtonItem()
        
        guard let image = previewImage else {
            return
        }

        photoImageView = UIImageView(image: image)
        photoImageView.contentMode = .scaleAspectFill
        let scaledHeight = view.frame.width / image.size.width * image.size.height
        
        photoImageView.frame = CGRect(x: 0,
                                      y: 0,
                                      width: self.view.frame.width,
                                      height: scaledHeight)
        
        self.view.addSubview(photoImageView)
        
        let request = VNDetectFaceRectanglesRequest { req, err in
            
            if let err = err {
                print(err.localizedDescription)
                return
            }
            
            req.results?.forEach({ res in
                guard let faceObservation = res as? VNFaceObservation else { return }
                print(faceObservation.boundingBox)
                
                let height = scaledHeight * faceObservation.boundingBox.height
                let width = self.view.frame.width * faceObservation.boundingBox.width
                let y = scaledHeight * (1 - faceObservation.boundingBox.origin.y) - height
                let x = self.view.frame.width * (1 - faceObservation.boundingBox.origin.x) - width
                
                let redView = UIView()
                redView.backgroundColor = .red
                redView.alpha = 0.3
                redView.frame = CGRect(x: x, y: y, width: width, height: height)
                self.view.addSubview(redView)
                self.redViews.append(redView)
                
                // make cropped Images
                
//                let newHeight = image.size.height * faceObservation.boundingBox.height
//                let newWidth = image.size.width * faceObservation.boundingBox.width
//                let newY = image.size.height * (1 - faceObservation.boundingBox.origin.y) - newHeight
//                let newX = image.size.width * (1 - faceObservation.boundingBox.origin.x) - newWidth
                
//                let cropRect = CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
//                guard let cgImage = self.previewImage?.cgImage else { return }
//                let cropped = cgImage.cropping(to: cropRect)!
                self.croppedImages.append(self.getCroppedImage(redView: redView))
                
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
    
    private func getCroppedImage(redView: UIView) -> UIImage {
        let imsize = photoImageView.image!.size
        let ivsize = photoImageView.bounds.size

        var scale : CGFloat = ivsize.width / imsize.width
        if imsize.height * scale < ivsize.height {
            scale = ivsize.height / imsize.height
        }

        let dispSize = CGSize(width:ivsize.width/scale, height:ivsize.height/scale)
        let dispOrigin = CGPoint(x: (imsize.width-dispSize.width)/2.0,
                                 y: (imsize.height-dispSize.height)/2.0)
        

        let r = self.redViews[0].convert(self.redViews[0].bounds, to: self.photoImageView)
        let cropRect =
        CGRect(x:r.origin.x/scale+dispOrigin.x,
               y:r.origin.y/scale+dispOrigin.y,
               width:r.width/scale,
               height:r.height/scale)
        
        let rend = UIGraphicsImageRenderer(size:cropRect.size)
        let croppedIm = rend.image { _ in
            self.photoImageView.image!.draw(at: CGPoint(x:-cropRect.origin.x,
                                            y:-cropRect.origin.y))
        }
         
        return croppedIm
    }
    
    
    public func setImage(_ image: UIImage) {
        self.previewImage = image
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
                            print("photo has saved in library...")
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.navigationController?.popViewController(animated: true)
                    }

                } catch let error {
                    print("failed to save photo in library: ", error)
                }
            } else {
                print("Something went wrong with permission...")
            }
        }
    }

}

