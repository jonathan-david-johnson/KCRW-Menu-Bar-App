//
//  ContentView.swift
//  KCRW MenuBar Player
//
//  Created by Jonathan Johnson on 10/4/22.
//

import SwiftUI
import AVFoundation


struct ContentView: View {
    
    @StateObject private var vm: SongListViewModel
    
//    @State var isPlaying = false
    
    init(vm: SongListViewModel) {
        self._vm = StateObject(wrappedValue: vm)
        
        do {
            let playerItem = AVPlayerItem(url: Constants.Urls.kcrwStream!)
            vm.audioPlayer = AVPlayer(playerItem: playerItem)
        }
    }
    
    var body: some View {
        
        if (vm.isPlaying) {
            VStack(alignment: .center) {
                Spacer()
                HStack(alignment: .center) {
                    Button(action: {
                        vm.isPlaying = false
                        vm.audioPlayer.replaceCurrentItem(with: nil)
                    }) { Text("Stop") }
                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }.keyboardShortcut("q")
                }

                ScrollViewReader { proxy in
                    List(vm.songs, id: \.play_id) { song in
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(song.title).fontWeight(.semibold)
                                Text(song.artist).opacity(0.4)
                                Text(song.album).opacity(0.4)
                            }
                            Spacer()
                            AsyncImage(url: URL(string: song.albumImage)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100)
                                case .failure, .empty:
                                    ZStack {
                                        Color.gray.opacity(0.2)
                                        Text("Go to Spotify")
                                            .font(.caption2)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(width: 100, height: 100)
                                @unknown default:
                                    Color.clear.frame(width: 100, height: 100)
                                }
                            }
                            .onTapGesture {
                                if let spotifyURL = URL(string: song.affiliateLinkSpotify) {
                                    NSWorkspace.shared.open(spotifyURL)
                                }
                            }
                        }
                    }
                    .onAppear {
                        if let firstSong = vm.songs.first {
                            proxy.scrollTo(firstSong.play_id, anchor: .top)
                        }
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(vm: SongListViewModel())
    }
}
