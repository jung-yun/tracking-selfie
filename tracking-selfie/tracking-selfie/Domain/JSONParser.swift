//
//  JSONParser.swift
//  tracking-selfie
//
//  Created by 조중윤 on 2022/03/16.
//

import Foundation

class JSONParser {
    static public let shared = JSONParser()
    
    private init() {}
    
    static public func parseDogPicResponse(_ data: Data) -> URL? {
        var result: URL?
        
        do {
            let dogPicData: [DogPicDataModel] = try JSONDecoder().decode([DogPicDataModel].self, from: data)
            result = URL(string: dogPicData[0].url)
        } catch {
            print("cannot parse response")
        }
        
        return result
    }
}
