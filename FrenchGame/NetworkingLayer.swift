//
//  NetworkingLayer.swift
//  FrenchGame
//
//  Created by Ido Ben-Natan on 9/7/18.
//

import Foundation
import SwiftHTTP

let SERVER_IP = "192.168.1.103:5000"

struct Response: Codable {
    let status: String
}

struct Chapters: Decodable {
    let data: [Chapter]
    let intro: [String]
    
    enum CodingKeys : String, CodingKey {
        case data = "data"
        case intro = "intro"
    }
}

struct Chapter: Decodable {
    let text: String
    let word: String
    
    enum CodingKeys : String, CodingKey {
        case text = "text"
        case word = "word"
    }
    
    static func getChapters(pin: Int, callback: @escaping (Chapters) -> ()) {
        HTTP.GET("http://\(SERVER_IP)/game/\(pin)/vocabulary") { (response) in
            
            requestSerializer: if let error = response.error {
                print("got an error: \(error)")
                return
            }
            
            guard let chapters = try? JSONDecoder().decode(Chapters.self, from: response.data) else {
                print("Error: Couldn't decode data into Blog")
                return
            }
            
            DispatchQueue.main.async {
                callback(chapters)
            }
        }
    }
}
