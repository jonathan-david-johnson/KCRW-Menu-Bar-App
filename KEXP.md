# KEXP Integration Research

## Stream URLs

- **64K AAC**: `https://kexp.streamguys1.com/kexp64.aac`
- **160K AAC**: `https://kexp.streamguys1.com/kexp160.aac`

## Tracklist API

- **Endpoint**: `https://api.kexp.org/v2/plays/?limit=10`
- **Format**: JSON with paginated results
- **Documentation**: Public API, no authentication required

## API Structure

KEXP uses a paginated structure with a `results` array, unlike KCRW's flat array.

### Example Response Structure

```json
{
  "next": "https://api.kexp.org/v2/plays/?limit=10&offset=10",
  "previous": null,
  "results": [...]
}
```

### Example Track Object

```json
{
  "id": 3609768,
  "uri": "https://api.kexp.org/v2/plays/3609768/",
  "airdate": "2026-01-27T11:12:13-08:00",
  "show": 65769,
  "show_uri": "https://api.kexp.org/v2/shows/65769/",
  "image_uri": "https://ia800506.us.archive.org/8/items/mbid-0a54174c-7a46-43f3-951e-b96bd9fbcb1f/mbid-0a54174c-7a46-43f3-951e-b96bd9fbcb1f-44140537063_thumb500.jpg",
  "thumbnail_uri": "https://ia600506.us.archive.org/8/items/mbid-0a54174c-7a46-43f3-951e-b96bd9fbcb1f/mbid-0a54174c-7a46-43f3-951e-b96bd9fbcb1f-44140537063_thumb250.jpg",
  "song": "Site Unseen",
  "track_id": "00e6e695-1ebc-40bf-bdba-0aeac6a1ea57",
  "recording_id": "4b4b01a0-109b-4a5a-bd1d-a67f760518a2",
  "artist": "Courtney Barnett feat. Waxahatchee",
  "artist_ids": [
    "42321e24-42b6-4f08-b0d9-8325ee887a20",
    "55111838-f001-494a-a1b5-9d818db85810"
  ],
  "album": "Creature of Habit",
  "release_id": "0a54174c-7a46-43f3-951e-b96bd9fbcb1f",
  "release_group_id": "86bd7034-660d-4f1d-96bf-1a70b81394ab",
  "labels": [
    "Mom + Pop Music"
  ],
  "label_ids": [
    "e30c6170-fcd5-4c30-9b89-bd1bdcbcaa5f"
  ],
  "release_date": "2026-03-27",
  "rotation_status": "Heavy",
  "is_local": false,
  "is_request": false,
  "is_live": false,
  "comment": "Courtney Barnett has announced a new album...",
  "location": 1,
  "location_name": "Default",
  "play_type": "trackplay"
}
```

## Field Mapping: KCRW vs KEXP

| Field | KCRW | KEXP |
|-------|------|------|
| Song title | `title` | `song` |
| Artist | `artist` | `artist` |
| Album | `album` | `album` |
| Album art | `albumImage` | `image_uri` or `thumbnail_uri` |
| Label | `label` (string) | `labels` (array) |
| Unique ID | `play_id` | `id` |
| Spotify link | `affiliateLinkSpotify` | ❌ Not provided |
| Date/time | `datetime` | `airdate` |
| Year | `year` | `release_date` |

## KEXP-Specific Fields

- **`play_type`**: `"trackplay"` for songs, `"airbreak"` for DJ commentary/station IDs
  - **Important**: Must filter for `play_type === "trackplay"` to get actual songs
- **`comment`**: DJ commentary about the track
- **`is_local`**: Boolean - indicates if artist is from Seattle area
- **`is_request`**: Boolean - listener request
- **`is_live`**: Boolean - live performance
- **`rotation_status`**: `"Heavy"`, `"Light"`, or `"Library"`
- **MusicBrainz IDs**: `track_id`, `recording_id`, `release_id`, `artist_ids`, `label_ids`

## Key Differences from KCRW

1. **Paginated Response**: Results wrapped in `results` array with `next`/`previous` pagination links
2. **No Spotify Links**: API doesn't provide Spotify affiliate links
   - Need to construct manually: `spotify:search:{artist}+{song}`
3. **Airbreaks Mixed In**: Response includes non-music entries (station IDs, DJ talk)
   - Filter by `play_type === "trackplay"`
4. **Labels as Array**: KEXP provides multiple labels, KCRW provides single string
5. **Better Metadata**: Includes MusicBrainz IDs, rotation status, local artist flags

## Implementation Considerations

### For Album Art Click-to-Spotify Feature
Since KEXP doesn't provide Spotify links, construct search URL:
```
spotify:search:{artist}+{song_title}
```

### For Song List Display
- Filter out entries where `play_type !== "trackplay"`
- Use `thumbnail_uri` for smaller images (250px) or `image_uri` for larger (500px)
- Handle `labels` array - either show first label or join with commas

### For Data Model
Can reuse existing `Song` model with field name adjustments, or create separate `KEXPSong` model.
