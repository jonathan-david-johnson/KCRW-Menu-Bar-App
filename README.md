# KCRW Menu Bar App

A macOS menu bar application that streams KCRW radio and displays currently playing songs.

## Overview

This is a native macOS SwiftUI application that lives in the menu bar, allowing users to:
- Stream KCRW radio (89.9 FM Los Angeles)
- View the current song and recently played tracks
- Control playback (start/stop) from the menu bar

## Architecture

### App Structure (MVVM Pattern)

```
KCRW MenuBar Player/
├── KCRW_MenuBar_PlayerApp.swift    # Main app entry point + AppDelegate
├── ContentView.swift                # Main UI view
├── Model/
│   └── Song.swift                   # Song data model
├── View Models/
│   └── SongListViewModel.swift      # Song list state + audio player management
├── Services/
│   └── Webservice.swift             # API networking layer
├── Utils/
│   └── Constants.swift              # API URLs and constants
└── Assets.xcassets/                 # Images (KCRW logos, app icons)
```

### Key Components

#### 1. **KCRW_MenuBar_PlayerApp.swift**
- **Main App**: `@main` entry point, minimal Settings scene
- **AppDelegate**: Core application logic
  - Creates `NSStatusItem` in menu bar with KCRW logo
  - Manages `NSPopover` for dropdown UI
  - Polls KCRW API every 30 seconds for song updates
  - Updates menu bar title with current song when playing
  - Handles play/stop state and audio player initialization

#### 2. **ContentView.swift**
- SwiftUI view displayed in the popover
- Shows Stop/Quit buttons when playing
- Displays scrollable list of recent songs with:
  - Song title (bold)
  - Artist name (dimmed)
  - Album name (dimmed)
- Initializes audio player with KCRW stream URL

#### 3. **SongListViewModel.swift**
- `@MainActor` class managing app state
- **Published properties**:
  - `isPlaying: Bool` - playback state
  - `songs: [SongViewModel]` - list of recent songs
  - `audioPlayer: AVPlayer` - audio player instance
- **Methods**:
  - `populateSongs()` - fetches latest songs from API
- **SongViewModel**: Wrapper struct providing safe access to optional Song properties

#### 4. **Song.swift**
- `Decodable` struct matching KCRW API response
- **Properties**: `title`, `artist`, `album`, `label`, `albumImage`, `year`, `artist_url`, `affiliateLinkSpotify`, `play_id`
- All properties are optional strings/int

#### 5. **Webservice.swift**
- Handles HTTP requests to KCRW API
- `getSongs(url:)` - async function returning `[Song]`
- Uses `URLSession` with basic error handling
- Throws `NetworkError.invalidResponse` on non-200 status

#### 6. **Constants.swift**
- **API Endpoints**:
  - `latestSongs`: `https://tracklist-api.kcrw.com/Music/all/1?page_size=10`
  - `kcrwStream`: `https://streams.kcrw.com/e24_mp3`

## Data Flow

1. **App Launch**:
   - `AppDelegate.applicationDidFinishLaunching()` creates menu bar item
   - Starts background task calling `updateRegularly()` every 30 seconds
   - Menu bar shows KCRW logo initially

2. **User Clicks Menu Bar Icon**:
   - `togglePopover()` called
   - If not playing: sets `isPlaying = true`, initializes `AVPlayer`, starts stream
   - Shows popover with `ContentView`

3. **Background Updates** (every 30s):
   - Calls `songListVM.populateSongs()` → fetches from API
   - If playing: updates menu bar title with current song
   - If stopped: shows KCRW logo

4. **User Stops Playback**:
   - Stop button sets `isPlaying = false`
   - Clears audio player
   - Menu bar reverts to logo

## Technical Details

### Frameworks Used
- **SwiftUI**: UI framework
- **AppKit**: `NSStatusItem`, `NSPopover`, `NSHostingController` for menu bar integration
- **AVFoundation**: `AVPlayer`, `AVPlayerItem` for audio streaming
- **Foundation**: `URLSession`, `JSONDecoder` for networking

### App Sandbox Entitlements
- `com.apple.security.app-sandbox`: Enabled
- `com.apple.security.network.client`: Required for streaming and API calls
- `com.apple.security.files.user-selected.read-only`: File access

### State Management
- Uses `@StateObject` and `@Published` for reactive UI updates
- `@MainActor` ensures UI updates on main thread
- `ObservableObject` protocol for view model

### Async/Await
- API calls use modern Swift concurrency
- Background tasks use `Task` with `sleep` for polling

## API Integration

### KCRW Tracklist API
- **Endpoint**: `https://tracklist-api.kcrw.com/Music/all/1?page_size=10`
- **Response**: JSON array of song objects
- **Update Frequency**: Polled every 30 seconds when app is running

### Audio Stream
- **URL**: `https://streams.kcrw.com/e24_mp3`
- **Format**: MP3 stream
- **Player**: AVPlayer with AVPlayerItem

## Known Limitations

1. **Song Title Scrolling**: `scrollThroughSongTitle()` function exists but only sets full title (no actual scrolling animation implemented)
2. **Album Images**: `AsyncImage` code commented out in ContentView
3. **UI Only Shows When Playing**: ContentView body returns empty view when `isPlaying = false`
4. **No Error UI**: Network errors only logged to console
5. **Fixed Polling**: 30-second update interval is hardcoded

## Testing Structure

- **KCRW MenuBar PlayerTests/**: Unit tests (basic XCTest setup)
- **KCRW MenuBar PlayerUITests/**: UI tests (basic XCTest setup)

## Development Notes

### To Modify Song Display
- Edit `ContentView.swift` body → List section
- Song data available via `vm.songs` array
- Each song accessed via `SongViewModel` wrapper

### To Change Update Frequency
- Modify `Task.sleep(nanoseconds:)` in `AppDelegate.updateRegularly()`
- Current: 30 seconds = 30_000_000_000 nanoseconds

### To Add Features to Menu Bar
- Extend `AppDelegate.togglePopover()` for custom actions
- Modify `statusItem.button` properties for menu bar appearance
- Add menu items via `NSMenu` if needed

### To Change API Endpoints
- Update `Constants.Urls` struct
- Ensure `Song` model matches API response structure

## Quick Reference for AI Assistants

**Main entry point**: `KCRW_MenuBar_PlayerApp.swift` → `AppDelegate`  
**UI**: `ContentView.swift`  
**State**: `SongListViewModel` in `View Models/SongListViewModel.swift`  
**Data model**: `Song` in `Model/Song.swift`  
**Networking**: `Webservice` in `Services/Webservice.swift`  
**Config**: `Constants` in `Utils/Constants.swift`

**Key state variable**: `SongListViewModel.isPlaying` controls entire app behavior  
**Audio player**: `SongListViewModel.audioPlayer` (AVPlayer instance)  
**Song list**: `SongListViewModel.songs` (array of SongViewModel)  
**Update loop**: `AppDelegate.updateRegularly()` - recursive async function with 30s delay
