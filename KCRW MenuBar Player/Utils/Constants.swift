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
        static let kcrwStream = URL(string: "https://kcrw.streamguys1.com/kcrw_192k_mp3_e24_internet_radio")
    }
}
