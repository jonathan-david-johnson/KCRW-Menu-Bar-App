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
    
    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🎵 KCRW App: applicationDidFinishLaunching called")
    
        self.songListVM = SongListViewModel()
        statusItem = NSStatusBar.system.statusItem(withLength: 60)
        print("🎵 KCRW App: Status item created: \(statusItem != nil)")
        
        if let statusButton = statusItem.button {
            print("🎵 KCRW App: Status button exists, setting image")
            let image = NSImage(named: "KCRW_logo_black")
            print("🎵 KCRW App: Image loaded: \(image != nil)")
            statusButton.image = image
            statusButton.title = "KCRW" // Fallback text
            print("🎵 KCRW App: Button title set to: \(statusButton.title)")
            print("🎵 KCRW App: Image set: \(statusButton.image != nil)")
            
            statusButton.action = #selector(togglePopover)
            
            self.popover = NSPopover()
            self.popover.contentSize = NSSize(width: 300, height: 300)
            self.popover.behavior = .transient
            self.popover.contentViewController = NSHostingController(rootView: ContentView(vm: self.songListVM))
        }
        
        
        func scrollThroughSongTitle() async {
            statusItem.button!.title = songName
        }
        
        func updateRegularly() async {
            await self.songListVM.populateSongs()
            
            if (self.songListVM.isPlaying && !self.songListVM.songs.isEmpty) {
                if (self.songListVM.songs[0].title != "") {
                    let song = self.songListVM.songs[0]
                    self.songName = song.title + " by " + song.artist
                } else {
                    self.songName = self.songListVM.songs[0].artist
                }
                statusItem.button!.image = nil
            } else {
                self.songName = "";
                statusItem.button!.image = NSImage(named: "KCRW_logo_black")
            }
            
            Task {
                songNameScrollIndex = 0
                await scrollThroughSongTitle();
            }
            
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
                }
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
        
    }
    
}
