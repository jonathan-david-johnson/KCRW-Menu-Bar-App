//
//  StockListViewModel.swift
//  KCRW MenuBar Player
//
//  Created by Jonathan Johnson on 10/4/22.
//

import Foundation
import AVFoundation


@MainActor
class SongListViewModel: ObservableObject {
    
    @Published var isPlaying: Bool = false;
    @Published var songs: [SongViewModel] = []
    @Published var audioPlayer: AVPlayer = AVPlayer();
    
    func populateSongs() async {
        
        do {
            let songsResp = try await Webservice().getSongs(url: Constants.Urls.latestSongs!)
            self.songs = songsResp.map(SongViewModel.init);
        } catch {
            print(error)
        }
    }
}


struct SongViewModel: Equatable {
    private var song: Song
    
    init(song: Song) {
        self.song = song
    }
    
    static func == (lhs: SongViewModel, rhs: SongViewModel) -> Bool {
        return lhs.play_id == rhs.play_id
    }
    
    var affiliateLinkSpotify: String {
        if song.affiliateLinkSpotify != nil {
            return song.affiliateLinkSpotify!
        }
        else {
            return ""
        }
    }
    
    var title: String {
        if song.title != nil {
            return song.title!
        }
        else {
            return ""
        }
    }
    
    var artist: String {
        if song.artist != nil {
            return song.artist!
        }
        else {
            return ""
        }
    }
    
    var album: String {
        if song.album != nil {
            return song.album!
        }
        else {
            return ""
        }
    }
    
    var label: String {
        if song.label != nil {
            return song.label!
        }
        else {
            return ""
        }
    }
    
    var albumImage: String {
        if song.albumImage != nil {
            return song.albumImage!
        }
        else {
            return ""
        }
    }
    
    var year: String {
        if song.year != nil {
            return song.year!
        }
        else {
            return ""
        }
    }
    
    var artist_url: String {
        if song.artist_url != nil {
            return song.artist_url!
        }
        else {
            return ""
        }
    }
    
    var play_id: Int {
        if song.play_id != nil {
            return song.play_id!
        }
        else {
            return -1
        }
    }
    
}
