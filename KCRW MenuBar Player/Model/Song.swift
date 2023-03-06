//
//  Stock.swift
//  KCRW MenuBar Player
//
//  Created by Jonathan Johnson on 10/4/22.
//

import Foundation


struct Song: Decodable {
    let affiliateLinkSpotify: String? // "spotify:search:KOKOROKO+Dide+O",
    let title: String? // "Dide O",
    let artist: String? // "KOKOROKO",
    let album: String? //"Could We Be More",
    let label: String? //"Brownswood Recordings",
    let albumImage: String? //"https://i.scdn.co/image/ab67616d00001e029a791fef4cb18f269cdcd9e3",
    let year: String? //"2022",
    let artist_url: String? //"https://www.kokorokomusic.co.uk/",
    let play_id: Int? // 23232
}
