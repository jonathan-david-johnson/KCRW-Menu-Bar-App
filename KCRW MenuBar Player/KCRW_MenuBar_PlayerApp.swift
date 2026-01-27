//
//  KCRW_MenuBar_PlayerApp.swift
//  KCRW MenuBar Player
//
//  Created by Jonathan Johnson on 10/4/22.
//

import SwiftUI
import AVFoundation

 
@main
struct KCRW_MenuBar_PlayerApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

 
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var songListVM: SongListViewModel!
    private var songName: String = ""
    private var songNameLengthLimit: Int = 20
    private var songNameScrollIndex: Int = 0
    private var isScrollingSongTitle: Bool = false
    private var scrollTask: Task<Void, Never>?
    private var currentStream: String = "kcrw" // Track which stream is playing
    
    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🎵 KCRW App: applicationDidFinishLaunching called")
    
        self.songListVM = SongListViewModel()
        statusItem = NSStatusBar.system.statusItem(withLength: 60)
        print("🎵 KCRW App: Status item created: \(statusItem != nil)")
        
        if let statusButton = statusItem.button {
            print("🎵 KCRW App: Status button exists, setting image")
            if let image = NSImage(named: "KCRW_logo_black") {
                let resizedImage = NSImage(size: NSSize(width: image.size.width * 0.5, height: image.size.height * 0.5))
                resizedImage.lockFocus()
                image.draw(in: NSRect(origin: .zero, size: resizedImage.size))
                resizedImage.unlockFocus()
                statusButton.image = resizedImage
                print("🎵 KCRW App: Image loaded and resized to 50%")
            }
            statusButton.title = ""
            print("🎵 KCRW App: Image set: \(statusButton.image != nil)")
            
            statusButton.action = #selector(togglePopover)
            
            self.popover = NSPopover()
            self.popover.contentSize = NSSize(width: 300, height: 300)
            self.popover.behavior = .transient
            self.popover.contentViewController = NSHostingController(rootView: ContentView(
                vm: self.songListVM,
                onStop: { [weak self] in
                    self?.popover.performClose(nil)
                    self?.updateMenuBar()
                },
                onStreamChange: { [weak self] stream in
                    self?.currentStream = stream
                    self?.updateMenuBar()
                }
            ))
        }
        
        
        func updateRegularly() async {
            print("🎵 KCRW App: Updating song list...")
            await self.songListVM.populateSongs()
            await self.songListVM.populateKEXPSongs()
            
            updateMenuBar()
            
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            await updateRegularly()
        }
        Task {
            await updateRegularly()
        }
        
    }
    

    
    @MainActor @objc func togglePopover() {
        
        if let button = statusItem.button {
            if popover.isShown {
                self.popover.performClose(nil)
            } else {
                if (!songListVM.isPlaying) {
                    self.songListVM.isPlaying = true
//                    self.songListVM.audioPlayer.play()
                    let playerItem = AVPlayerItem(url: Constants.Urls.kcrwStream!)
                    self.songListVM.audioPlayer = AVPlayer(playerItem: playerItem)
                    self.songListVM.audioPlayer.play()
                    updateMenuBar()
                }
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
        
    }
    
    func scrollThroughSongTitle() async {
        guard !songName.isEmpty else { return }
        
        if let button = statusItem.button {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 10),
                .paragraphStyle: paragraphStyle,
                .baselineOffset: 0
            ]
            
            // If 9 chars or less, just show it
            if songName.count <= 9 {
                button.attributedTitle = NSAttributedString(string: songName, attributes: attributes)
                return
            }
            
            // Scroll through the text
            let maxIndex = songName.count - 9
            for i in 0...maxIndex {
                // Check if task was cancelled
                if Task.isCancelled { return }
                
                let startIndex = songName.index(songName.startIndex, offsetBy: i)
                let endIndex = songName.index(startIndex, offsetBy: 9)
                let substring = String(songName[startIndex..<endIndex])
                
                button.attributedTitle = NSAttributedString(string: substring, attributes: attributes)
                
                // Hold at the start for 1 second before scrolling
                if i == 0 {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                } else {
                    try? await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds
                }
            }
            
            // Hold at the end for 1 second
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Check if task was cancelled before restarting
            if !Task.isCancelled {
                await scrollThroughSongTitle()
            }
        }
    }
    
    @MainActor
    func updateMenuBar() {
        if (self.songListVM.isPlaying) {
            if currentStream == "kcrw" && !self.songListVM.songs.isEmpty {
                if (self.songListVM.songs[0].title != "") {
                    let song = self.songListVM.songs[0]
                    self.songName = song.title + " by " + song.artist
                } else {
                    self.songName = self.songListVM.songs[0].artist
                }
            } else if currentStream == "kexp" && !self.songListVM.kexpSongs.isEmpty {
                if (self.songListVM.kexpSongs[0].title != "") {
                    let song = self.songListVM.kexpSongs[0]
                    self.songName = song.title + " by " + song.artist
                } else {
                    self.songName = self.songListVM.kexpSongs[0].artist
                }
            }
            statusItem.button!.image = nil
        } else {
            self.songName = "";
            statusItem.button!.title = ""
            statusItem.button!.attributedTitle = NSAttributedString(string: "")
            if let image = NSImage(named: "KCRW_logo_black") {
                let resizedImage = NSImage(size: NSSize(width: image.size.width * 0.5, height: image.size.height * 0.5))
                resizedImage.lockFocus()
                image.draw(in: NSRect(origin: .zero, size: resizedImage.size))
                resizedImage.unlockFocus()
                statusItem.button!.image = resizedImage
            }
        }
        
        // Cancel previous scroll task and start new one
        scrollTask?.cancel()
        scrollTask = Task {
            songNameScrollIndex = 0
            await scrollThroughSongTitle()
        }
    }
    
}
