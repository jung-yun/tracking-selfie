//
//  NetworkError.swift
//  tracking-selfie
//
//  Created by 조중윤 on 2022/03/16.
//

import Foundation

enum NetworkError: String, Error {
    case unableToComplete = "Unable to complete your request. Please check your internet connection."
    case invalidResponse = "Invalid response from the server. Please try again."
    case invalidData = "The data received from the server was invalid. Please try again."
}
