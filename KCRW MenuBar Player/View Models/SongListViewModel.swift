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
    @Published var kexpSongs: [KEXPSongViewModel] = []
    @Published var audioPlayer: AVPlayer = AVPlayer();
    
    private var kcrwInitialLoad = true
    private var kexpInitialLoad = true
    
    func populateSongs() async {
        do {
            let pageSize = kcrwInitialLoad ? 10 : 1
            let url = URL(string: "https://tracklist-api.kcrw.com/Music/all/1?page_size=\(pageSize)")!
            let songsResp = try await Webservice().getSongs(url: url)
            
            if kcrwInitialLoad {
                self.songs = songsResp.map(SongViewModel.init)
                kcrwInitialLoad = false
            } else if !songsResp.isEmpty {
                let newSong = SongViewModel(song: songsResp[0])
                // Only add if it's actually new (different play_id)
                if songs.isEmpty || newSong.play_id != songs[0].play_id {
                    self.songs.insert(newSong, at: 0)
                    // Keep only 10 tracks
                    if self.songs.count > 10 {
                        self.songs.removeLast()
                    }
                }
            }
        } catch {
            print(error)
        }
    }
    
    func populateKEXPSongs() async {
        do {
            let pageSize = kexpInitialLoad ? 10 : 1
            let url = URL(string: "https://api.kexp.org/v2/plays/?limit=\(pageSize)")!
            let songsResp = try await Webservice().getKEXPSongs(url: url)
            
            if kexpInitialLoad {
                self.kexpSongs = songsResp.map(KEXPSongViewModel.init)
                kexpInitialLoad = false
            } else if !songsResp.isEmpty {
                let newSong = KEXPSongViewModel(song: songsResp[0])
                // Only add if it's actually new (different id)
                if kexpSongs.isEmpty || newSong.id != kexpSongs[0].id {
                    self.kexpSongs.insert(newSong, at: 0)
                    // Keep only 10 tracks
                    if self.kexpSongs.count > 10 {
                        self.kexpSongs.removeLast()
                    }
                }
            }
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

struct KEXPSongViewModel: Equatable {
    private var song: KEXPSong
    
    init(song: KEXPSong) {
        self.song = song
    }
    
    static func == (lhs: KEXPSongViewModel, rhs: KEXPSongViewModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id: Int {
        return song.id ?? -1
    }
    
    var title: String {
        return song.song ?? ""
    }
    
    var artist: String {
        return song.artist ?? ""
    }
    
    var album: String {
        return song.album ?? ""
    }
    
    var albumImage: String {
        return song.thumbnail_uri ?? song.image_uri ?? ""
    }
    
    var label: String {
        return song.labels?.first ?? ""
    }
    
    var musicbrainzURL: String {
        if let releaseId = song.release_id {
            return "https://musicbrainz.org/release/\(releaseId)"
        }
        return ""
    }
}
