//
//  Constants.swift
//  KCRW MenuBar Player
//
//  Created by Jonathan Johnson on 10/4/22.
//

import Foundation

struct Constants {
    
    struct Urls {
        static let latestSongs = URL(string: "https://tracklist-api.kcrw.com/Music/all/1?page_size=10")
        static let kcrwStream = URL(string: "https://streams.kcrw.com/e24_mp3")
    }
}
