//
//  DogPicService.swift
//  tracking-selfie
//
//  Created by 조중윤 on 2022/03/16.
//

import UIKit

final class DogPicService {
    private var networkController: NetworkController? = nil
    
    init(networkController: NetworkController) {
        self.networkController = networkController
    }
    
    func getRandomDogPic(completionHandler: @escaping (Result<UIImage, NetworkError>) -> Void) {
        self.networkController?.getRandomDogPic(completionHandler: { result in
            switch result {
            case .success(let data):
                guard let imageURL = JSONParser.parseDogPicResponse(data) else {
                    completionHandler(.failure(.unableToComplete)); return}
                
                if let imageData = try? Data(contentsOf: imageURL) {
                    if let image = UIImage(data: imageData) {
                        completionHandler(.success(image))
                    }
                }
                
//                completionHandler(.failure(.unableToComplete))
            case.failure(let networkError):
                completionHandler(.failure(networkError))
            }
        })
    }
    
    
}
