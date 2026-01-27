//
//  KEXPSong.swift
//  KCRW MenuBar Player
//

import Foundation

struct KEXPResponse: Decodable {
    let results: [KEXPSong]
}

struct KEXPSong: Decodable {
    let id: Int?
    let song: String?
    let artist: String?
    let album: String?
    let thumbnail_uri: String?
    let image_uri: String?
    let labels: [String]?
    let release_id: String?
    let play_type: String?
}
