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
    
        @State var currentNumber: String = "1"
    var body: some Scene {
//        WindowGroup {
//            ContentView(vm: SongListViewModel())
//        }
        
        
        MenuBarExtra(currentNumber, systemImage: "") {
        
                           // 3
                   Button("One") {
                       currentNumber = "1"
                   }
                   Button("Two") {
                       currentNumber = "2"
                   }
                   Button("Three") {
                       currentNumber = "3"
                   }
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
    
        self.songListVM = SongListViewModel()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let statusButton = statusItem.button {
            statusButton.image = NSImage(named: "KCRW_logo_black")
            
            statusButton.action = #selector(togglePopover)
            
            self.popover = NSPopover()
            self.popover.contentSize = NSSize(width: 300, height: 300)
            self.popover.behavior = .transient
            self.popover.contentViewController = NSHostingController(rootView: ContentView(vm: self.songListVM))
        }
        
        
        func scrollThroughSongTitle() async {
           /* let snipitOfName:String;
            if (songName.count < songNameLengthLimit) {
                snipitOfName = songName
            }
            else {
                let rangeStart = songName.index(songName.startIndex, offsetBy: songNameScrollIndex)
                let rangeEnd = songName.index(songName.startIndex, offsetBy: songNameScrollIndex + songNameLengthLimit)

                snipitOfName = String(songName[rangeStart..<rangeEnd])
            }

            if (songNameScrollIndex + songNameLengthLimit == songName.count) {
                songNameScrollIndex = 0
            } else {
                songNameScrollIndex = songNameScrollIndex + 1
            }
            statusItem.button!.title = snipitOfName;

            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await scrollThroughSongTitle()
            */
            statusItem.button!.title = songName;
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
