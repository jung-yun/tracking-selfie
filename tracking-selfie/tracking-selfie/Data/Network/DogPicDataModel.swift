//
//  DogPicData.swift
//  tracking-selfie
//
//  Created by 조중윤 on 2022/03/16.
//

import Foundation

// MARK: - WelcomeElement
struct DogPicDataModel: Codable {
    let breeds: [Breed]
    let height: Int
    let id: String
    let url: String
    let width: Int
}

// MARK: - Breed
struct Breed: Codable {
    let bredFor, breedGroup: String
    let height: Eight
    let id: Int
    let lifeSpan, name, referenceImageID, temperament: String
    let weight: Eight

    enum CodingKeys: String, CodingKey {
        case bredFor = "bred_for"
        case breedGroup = "breed_group"
        case height, id
        case lifeSpan = "life_span"
        case name
        case referenceImageID = "reference_image_id"
        case temperament, weight
    }
}

// MARK: - Eight
struct Eight: Codable {
    let imperial, metric: String
}
