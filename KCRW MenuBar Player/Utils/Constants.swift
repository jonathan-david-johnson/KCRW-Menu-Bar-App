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
        static let kexpStream = URL(string: "https://kexp.streamguys1.com/kexp160.aac")
        static let kexpPlays = URL(string: "https://api.kexp.org/v2/plays/?limit=10")
    }
}
