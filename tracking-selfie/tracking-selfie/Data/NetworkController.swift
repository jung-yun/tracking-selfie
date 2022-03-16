//
//  NetworkController.swift
//  tracking-selfie
//
//  Created by 조중윤 on 2022/03/16.
//

import UIKit

final class NetworkController {
    private var sessionManager: SessionManagerProtocol!
    
    init(sessionManager: SessionManagerProtocol) {
        self.sessionManager = sessionManager
    }
    
    func getRandomDogPic(using session: URLSession = .shared,
                         completionHandler: ((Swift.Result<Data, NetworkError>) -> Void)?) {
 
        let req = sessionManager.makeRandomDogPictureRequest()
        
        let task = session.dataTask(with: req) { data, response, error in
            
            if let _ = error {
                // handling transport error
                completionHandler?(.failure(NetworkError.unableToComplete))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completionHandler?(.failure(NetworkError.invalidResponse))
                return
            }
            
            guard let data = data else {
                completionHandler?(.failure(NetworkError.invalidData))
                return
            }
            
            switch httpResponse.statusCode {
                
            case 200...299 :
                completionHandler?(.success(data))
                return
            default:
                completionHandler?(.failure(NetworkError.invalidResponse))
                return
            }
        }

        task.resume()
    }
    
}
