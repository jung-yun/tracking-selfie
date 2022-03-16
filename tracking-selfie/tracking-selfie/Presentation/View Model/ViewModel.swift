//
//  ViewModel.swift
//  tracking-selfie
//
//  Created by 조중윤 on 2022/03/16.
//

import Photos
import UIKit

protocol LocalPhotoLibraryUsable {
    func save(photos: [UIImage], completionHandler: @escaping (Result<Void, PhotoSaveError>) -> Void)
}

protocol DogPicDownloadable {
    func getRandomDogPic(completionHandler: @escaping (UIImage) -> Void)
}


enum PhotoSaveError: String, Error {
    case cannotAccessPhotoLibrary = "Cannot Access To Photo Library"
    case cannotSavePhotoToLibrary = "Cannot Save Photo to Photo Library"
}

final class ViewModel: LocalPhotoLibraryUsable {
    private var dogPicService: DogPicService?
    
    init(dogPicService: DogPicService) {
        self.dogPicService = dogPicService
    }
    
    func save(photos: [UIImage], completionHandler: @escaping (Result<Void, PhotoSaveError>) -> Void) {
        PHPhotoLibrary.requestAuthorization { (status) in
            if status == .authorized {
                for photo in photos {
                    do {
                        //performChangesAndWait -> Synchronous
                        try PHPhotoLibrary.shared().performChangesAndWait {
                            PHAssetChangeRequest.creationRequestForAsset(from: photo)
                        }
                    } catch {
                        completionHandler(.failure(.cannotSavePhotoToLibrary))
                    }
                    
                    completionHandler(.success(()))
                }
            } else {
                completionHandler(.failure(.cannotAccessPhotoLibrary))
            }
        }
    }
    
}

extension ViewModel: DogPicDownloadable {
    func getRandomDogPic(completionHandler: @escaping (UIImage) -> Void) {
        self.dogPicService?.getRandomDogPic(completionHandler: { result in
            switch result {
            case.success(let dogImage):
                completionHandler(dogImage)
            case.failure(let networkError):
                print(networkError.rawValue)
                completionHandler(UIImage.init(systemName: "x.circle") ?? UIImage())
            }
        })
    }
}
