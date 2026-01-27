# KCRW Menu Bar App

A macOS menu bar application that streams multiple radio stations and displays currently playing songs.

## Overview

This is a native macOS SwiftUI application that lives in the menu bar, allowing users to:
- Stream KCRW radio (89.9 FM Los Angeles)
- Stream KEXP radio (90.3 FM Seattle)
- Play NPR News Now hourly updates
- View current songs and recently played tracks for KCRW and KEXP
- Control playback (start/stop) from the menu bar
- Skip forward in NPR News with time remaining display

## Building and Installing

### Quick Build (Recommended for Development)

1. **Open the project**:
   ```bash
   open "KCRW MenuBar Player.xcodeproj"
   ```

2. **Build and run**:
   - In Xcode, select "My Mac" as destination
   - Click the Play button (▶️) or press `Cmd+R`
   - The app will launch immediately

3. **Install to Applications folder**:
   - While the app is running, right-click the app icon in the Dock
   - Select **Options → Show in Finder**
   - Copy the `.app` file to `/Applications`

### Alternative: Build from Menu

1. In Xcode, select "My Mac" as destination
2. Click **Product → Build** (or `Cmd+B`)
3. Click **Product → Show Build Folder in Finder**
4. Navigate to `Products/Debug/`
5. Drag `KCRW MenuBar Player.app` to your Applications folder

### Archive for Distribution

1. In Xcode, select "My Mac" as destination
2. Choose **Product → Archive** from the menu
3. Wait for the build to complete
4. In the Organizer window (**Window → Organizer** or `Cmd+Shift+Option+O`):
   - Click the **Archives** tab
   - Select your archive
   - Click **Distribute App**
   - Select **Copy App**
   - Choose a location to save the `.app` file
5. Drag the `.app` file to `/Applications`

**Note**: If you get security warnings when launching, go to **System Settings → Privacy & Security** and click "Open Anyway"

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
  - Creates `NSStatusItem` in menu bar with logo
  - Manages `NSPopover` for dropdown UI
  - Polls KCRW and KEXP APIs every 30 seconds for song updates
  - Updates menu bar title with current song when playing (with scrolling animation)
  - Handles play/stop state and audio player initialization
  - Tracks current stream (KCRW, KEXP, or NPR)

#### 2. **ContentView.swift**
- SwiftUI view displayed in the popover
- **Stream Selection**: Dropdown to choose KCRW, KEXP, or NPR
- **Tracklist Tabs**: Segmented picker to view KCRW or KEXP tracklists
- **NPR Controls**: Skip forward button showing time remaining (when NPR is playing)
- **Stop/Quit buttons**: Control playback
- Displays scrollable list of recent songs with:
  - Song title (bold)
  - Artist name (dimmed)
  - Album name (dimmed)
  - Album art (clickable - opens Spotify for KCRW, MusicBrainz for KEXP)

#### 3. **SongListViewModel.swift**
- `@MainActor` class managing app state
- **Published properties**:
  - `isPlaying: Bool` - playback state
  - `songs: [SongViewModel]` - list of recent KCRW songs
  - `kexpSongs: [KEXPSongViewModel]` - list of recent KEXP songs
  - `audioPlayer: AVPlayer` - audio player instance
- **Methods**:
  - `populateSongs()` - fetches latest KCRW songs (10 on first load, then 1 per update)
  - `populateKEXPSongs()` - fetches latest KEXP songs (10 on first load, then 1 per update)
- **SongViewModel**: Wrapper struct providing safe access to optional Song properties
- **KEXPSongViewModel**: Wrapper for KEXP songs with MusicBrainz URL generation

#### 4. **Song.swift**
- **Song**: `Decodable` struct matching KCRW API response
  - Properties: `title`, `artist`, `album`, `label`, `albumImage`, `year`, `artist_url`, `affiliateLinkSpotify`, `play_id`
- **KEXPSong**: `Decodable` struct matching KEXP API response
  - Properties: `id`, `song`, `artist`, `album`, `thumbnail_uri`, `image_uri`, `labels`, `release_id`, `play_type`
- **KEXPResponse**: Wrapper for paginated KEXP API results

#### 5. **Webservice.swift**
- Handles HTTP requests to KCRW and KEXP APIs
- `getSongs(url:)` - async function returning `[Song]`
- `getKEXPSongs(url:)` - async function returning `[KEXPSong]` (filters out airbreaks)
- Uses `URLSession` with basic error handling
- Throws `NetworkError.invalidResponse` on non-200 status

#### 6. **Constants.swift**
- **API Endpoints**:
  - `latestSongs`: `https://tracklist-api.kcrw.com/Music/all/1?page_size=10`
  - `kcrwStream`: `https://streams.kcrw.com/e24_mp3`
  - `kexpStream`: `https://kexp.streamguys1.com/kexp160.aac`
  - `kexpPlays`: `https://api.kexp.org/v2/plays/?limit=10`

## Data Flow

1. **App Launch**:
   - `AppDelegate.applicationDidFinishLaunching()` creates menu bar item
   - Starts background task calling `updateRegularly()` every 30 seconds
   - Menu bar shows KCRW logo initially

2. **User Clicks Menu Bar Icon**:
   - `togglePopover()` called
   - If not playing: sets `isPlaying = true`
   - Shows popover with `ContentView`
   - ContentView starts playing the selected stream (KCRW, KEXP, or NPR)

3. **Stream Selection**:
   - User selects stream from dropdown (KCRW, KEXP, or NPR)
   - For KCRW/KEXP: Plays live stream URL
   - For NPR: Fetches latest episode from RSS feed and plays MP3
   - Menu bar text updates immediately to show current stream info

4. **Background Updates** (every 30s):
   - Calls `songListVM.populateSongs()` and `populateKEXPSongs()`
   - First load: fetches 10 tracks; subsequent loads: fetches 1 track
   - New tracks prepended to list, keeping max 10 tracks
   - If playing: updates menu bar title with current song (scrolling animation)
   - If stopped: shows KCRW logo

5. **User Stops Playback**:
   - Stop button sets `isPlaying = false`
   - Clears audio player
   - Menu bar reverts to logo
   - Selected stream is preserved for next play

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

#### Example API Response
```json
{
  "affiliateLinkiPhone": "https://itunes.apple.com/WebObjects/MZStore.woa/wa/search?at=1010l3dvo&media=music&term=%22Rickie+Lee+Jones%22+%22The+Last+Chance+Texaco%22",
  "affiliateLinkiTunes": "https://itunes.apple.com/WebObjects/MZStore.woa/wa/search?at=1010l3dvo&media=music&term=%22Rickie+Lee+Jones%22+%22The+Last+Chance+Texaco%22",
  "affiliateLinkSpotify": "spotify:search:Rickie+Lee+Jones+The+Last+Chance+Texaco",
  "affiliateLinkAmazon": "http://www.amazon.com/exec/obidos/external-search?keyword=Rickie+Lee+Jones+The+Last+Chance+Texaco&mode=digital-music&tag=kcco04-20",
  "itunes_id": 1421847342,
  "itunes_time": 245467,
  "itunes_url": "https://music.apple.com/us/album/the-last-chance-texaco/1421846869?i=1421847342&uo=4&itscg=30200&itsct=kcrw_music&at=1010l3dvo",
  "spotify_id": null,
  "spotify_preview": null,
  "program_id": "e24",
  "program_start": "03:00",
  "program_end": "06:00",
  "program_title": "Eclectic 24",
  "host": "",
  "credits": null,
  "guest": null,
  "title": "The Last Chance Texaco",
  "artist": "Rickie Lee Jones",
  "album": "Rickie Lee Jones",
  "label": "TOSOD",
  "albumImage": "https://is5-ssl.mzstatic.com/image/thumb/Music115/v4/21/c3/06/21c3064e-411c-8280-e951-8285eb167f4c/source/100x100bb.jpg",
  "albumImageLarge": "https://is5-ssl.mzstatic.com/image/thumb/Music115/v4/21/c3/06/21c3064e-411c-8280-e951-8285eb167f4c/source/100x100bb.jpg",
  "year": null,
  "artist_url": "http://www.rickieleejones.com/",
  "channel": "Music",
  "offset": 9521,
  "time": "05:38 AM",
  "date": "2026-01-27",
  "datetime": "2026-01-27T05:38:41-08:00",
  "comments": "",
  "play_id": 997040
}
```

**Note**: The `Song` model only decodes a subset of these fields: `title`, `artist`, `album`, `label`, `albumImage`, `year`, `artist_url`, `affiliateLinkSpotify`, `play_id`

### KEXP Tracklist API
- **Endpoint**: `https://api.kexp.org/v2/plays/?limit=10`
- **Response**: JSON with paginated results
- **Update Frequency**: Polled every 30 seconds when app is running
- **Filtering**: Filters out `play_type === "airbreak"` entries to show only actual songs

### NPR News Now
- **RSS Feed**: `https://feeds.npr.org/500005/podcast.xml`
- **Format**: Hourly 5-minute news updates as MP3 files
- **Playback**: Fetches latest episode URL from RSS feed and plays directly
- **Controls**: Skip forward 10 seconds with time remaining display

### Audio Streams
- **KCRW**: `https://streams.kcrw.com/e24_mp3` (MP3 stream)
- **KEXP**: `https://kexp.streamguys1.com/kexp160.aac` (160K AAC stream)
- **NPR**: Dynamic MP3 URL from RSS feed
- **Player**: AVPlayer with AVPlayerItem

## Known Limitations

1. **No NPR Tracklist**: NPR News Now doesn't show a tracklist (just placeholder text)
2. **UI Only Shows When Playing**: ContentView body returns empty view when `isPlaying = false`
3. **No Error UI**: Network errors only logged to console
4. **Fixed Polling**: 30-second update interval is hardcoded

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
