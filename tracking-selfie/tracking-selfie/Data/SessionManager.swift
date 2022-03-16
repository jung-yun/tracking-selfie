//
//  SessionManager.swift
//  tracking-selfie
//
//  Created by 조중윤 on 2022/03/16.
//

import Foundation

protocol SessionManagerProtocol {
    func makeRandomDogPictureRequest() -> URLRequest
}

final class SessionManager: SessionManagerProtocol {
    func makeRandomDogPictureRequest() -> URLRequest {
        let endpoint = Endpoint.randomDogPicture()
        var request = URLRequest(url: endpoint.url)
        
        // the api key will possibly changed
        request.setValue("5a3568e2-0d92-4fff-8477-78b65dde3691",
                         forHTTPHeaderField: "x-api-key")
        
        request.httpMethod = HTTPMethod.get.rawValue
        return request
    }
}
