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

                List(vm.songs, id: \.play_id) { song in
                    HStack(alignment: .center) {
                        VStack(alignment: .leading) {
                            Text(song.title).fontWeight(.semibold)
                            Text(song.artist).opacity(0.4)
                            Text(song.album).opacity(0.4)
                            Divider()
                        }
//                        AsyncImage(url: URL(string: song.albumImage)).frame(width: 15, height: 15)
                        Spacer()
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
