//
//  Webservice.swift
//  KCRW MenuBar Player
//
//  Created by Jonathan Johnson on 10/4/22.
//

import Foundation

enum NetworkError: Error {
    case invalidResponse
}
class Webservice {
    
    func getSongs(url: URL) async throws -> [Song] {
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
//        print("data response", data)
        return try JSONDecoder().decode([Song].self, from: data)
    }
    
    func getKEXPSongs(url: URL) async throws -> [KEXPSong] {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        let kexpResponse = try JSONDecoder().decode(KEXPResponse.self, from: data)
        // Filter out airbreaks, only return actual tracks
        return kexpResponse.results.filter { $0.play_type == "trackplay" }
    }
}
