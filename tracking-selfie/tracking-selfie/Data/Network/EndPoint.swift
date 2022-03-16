//
//  EndPoint.swift
//  tracking-selfie
//
//  Created by 조중윤 on 2022/03/16.
//

import Foundation

struct Endpoint {
    var host: String
    var path: String
    var queryItems: [URLQueryItem] = []
}

extension Endpoint {
    var url: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = self.host
        components.path = "/" + self.path
        components.queryItems = self.queryItems
        
        guard let url = components.url else {
            preconditionFailure(
                "Invalid URL components: \(components)"
            )
        }
        
        return url
    }
}

extension Endpoint {
    static func randomDogPicture() -> Self {
        return Endpoint(host: "api.thedogapi.com",
                        path: "v1/images/search",
                        queryItems: [URLQueryItem(name: "limit", value: "1")])
    }
}
