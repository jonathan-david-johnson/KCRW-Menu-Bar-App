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
    @State private var selectedStation: Station = .kcrw
    @State private var selectedStream: Station = .kcrw
    @State private var timeRemaining: String = "0:00"
    @State private var hasAppeared: Bool = false
    var onStop: (() -> Void)?
    var onStreamChange: ((String) -> Void)?
    
    enum Station {
        case kcrw
        case kexp
        case npr
    }
    
//    @State var isPlaying = false
    
    init(vm: SongListViewModel, onStop: (() -> Void)? = nil, onStreamChange: ((String) -> Void)? = nil) {
        self._vm = StateObject(wrappedValue: vm)
        self.onStop = onStop
        self.onStreamChange = onStreamChange
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack(alignment: .center) {
                Picker("", selection: $selectedStream) {
                        Text("KCRW").tag(Station.kcrw)
                        Text("KEXP").tag(Station.kexp)
                        Text("NPR").tag(Station.npr)
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(minWidth: 100)
                    .onChange(of: selectedStream) { newStream in
                        switchStream(to: newStream)
                    }
                    
                    Spacer()
                    
                    if selectedStream == .npr {
                        Button(action: {
                            skipForward()
                        }) { 
                            Text(timeRemaining)
                                .frame(width: 35)
                        }
                        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
                            updateTimeRemaining()
                        }
                    }
                    
                    if selectedStream == .npr {
                        Button(action: {
                            skipBackward()
                        }) { Text("<<") }
                    }
                    
                    Button(action: {
                        togglePlayback()
                    }) {
                        Image(systemName: vm.isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 10))
                    }
                    
                    if selectedStream == .npr {
                        Button(action: {
                            skipForward()
                        }) { Text(">>") }
                    }
                    
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                    }
                    .keyboardShortcut("q")
                }
                .padding(.top, 8)
                .padding(.horizontal, 8)
                
                Picker("", selection: $selectedStation) {
                    Text("KCRW").tag(Station.kcrw)
                    Text("KEXP").tag(Station.kexp)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                
                switch selectedStation {
                case .kcrw:
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
                    .onChange(of: vm.songs) { _ in
                        if let firstSong = vm.songs.first {
                            proxy.scrollTo(firstSong.play_id, anchor: .top)
                        }
                    }
                    .onAppear {
                        if let firstSong = vm.songs.first {
                            proxy.scrollTo(firstSong.play_id, anchor: .top)
                        }
                    }
                }
                
                case .kexp:
                    ScrollViewReader { proxy in
                        List(vm.kexpSongs, id: \.id) { song in
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
                                            Text("MusicBrainz")
                                                .font(.caption2)
                                                .multilineTextAlignment(.center)
                                        }
                                        .frame(width: 100, height: 100)
                                    @unknown default:
                                        Color.clear.frame(width: 100, height: 100)
                                    }
                                }
                                .onTapGesture {
                                    if let url = URL(string: song.musicbrainzURL) {
                                        NSWorkspace.shared.open(url)
                                    }
                                }
                            }
                        }
                        .onChange(of: vm.kexpSongs) { _ in
                            if let firstSong = vm.kexpSongs.first {
                                proxy.scrollTo(firstSong.id, anchor: .top)
                            }
                        }
                        .onAppear {
                            Task {
                                await vm.populateKEXPSongs()
                            }
                            if let firstSong = vm.kexpSongs.first {
                                proxy.scrollTo(firstSong.id, anchor: .top)
                            }
                        }
                    }
                
                case .npr:
                    Text("NPR News Now")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .onAppear {
                if !hasAppeared {
                    hasAppeared = true
                    vm.isPlaying = true
                    switchStream(to: selectedStream)
                }
            }
    }
    
    private func switchStream(to station: Station) {
        let streamName: String
        switch station {
        case .kcrw:
            streamName = "kcrw"
            if let url = Constants.Urls.kcrwStream {
                let playerItem = AVPlayerItem(url: url)
                vm.audioPlayer.replaceCurrentItem(with: playerItem)
                vm.audioPlayer.play()
            }
        case .kexp:
            streamName = "kexp"
            if let url = Constants.Urls.kexpStream {
                let playerItem = AVPlayerItem(url: url)
                vm.audioPlayer.replaceCurrentItem(with: playerItem)
                vm.audioPlayer.play()
            }
        case .npr:
            streamName = "npr"
            Task {
                await playLatestNPRNews()
            }
        }
        
        onStreamChange?(streamName)
    }
    
    private func playLatestNPRNews() async {
        do {
            let url = URL(string: "https://feeds.npr.org/500005/podcast.xml")!
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let xmlString = String(data: data, encoding: .utf8),
               let enclosureStart = xmlString.range(of: "<enclosure"),
               let urlStart = xmlString[enclosureStart.lowerBound...].range(of: "url=\""),
               let urlEnd = xmlString[urlStart.upperBound...].range(of: "\"") {
                
                let audioURLString = String(xmlString[urlStart.upperBound..<urlEnd.lowerBound])
                if let audioURL = URL(string: audioURLString) {
                    let playerItem = AVPlayerItem(url: audioURL)
                    await MainActor.run {
                        vm.audioPlayer.replaceCurrentItem(with: playerItem)
                        vm.audioPlayer.play()
                    }
                }
            }
        } catch {
            print("Error fetching NPR News: \(error)")
        }
    }
    
    private func skipBackward() {
        let currentTime = vm.audioPlayer.currentTime()
        let newTime = CMTimeSubtract(currentTime, CMTime(seconds: 10, preferredTimescale: 1))
        vm.audioPlayer.seek(to: newTime)
    }
    
    private func skipForward() {
        let currentTime = vm.audioPlayer.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: 10, preferredTimescale: 1))
        vm.audioPlayer.seek(to: newTime)
    }
    
    private func updateTimeRemaining() {
        guard let currentItem = vm.audioPlayer.currentItem else {
            timeRemaining = "0:00"
            return
        }
        
        let duration = currentItem.duration
        let currentTime = vm.audioPlayer.currentTime()
        
        guard duration.isValid && !duration.isIndefinite else {
            timeRemaining = "0:00"
            return
        }
        
        let remaining = CMTimeSubtract(duration, currentTime)
        let seconds = Int(CMTimeGetSeconds(remaining))
        
        if seconds >= 0 {
            let minutes = seconds / 60
            let secs = seconds % 60
            timeRemaining = String(format: "%d:%02d", minutes, secs)
        } else {
            timeRemaining = "0:00"
        }
    }
    
    private func togglePlayback() {
        if vm.isPlaying {
            vm.isPlaying = false
            vm.audioPlayer.replaceCurrentItem(with: nil)
        } else {
            vm.isPlaying = true
            switchStream(to: selectedStream)
        }
        onStop?()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(vm: SongListViewModel())
    }
}
