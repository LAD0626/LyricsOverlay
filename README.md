# LyricsOverlay

LyricsOverlay is a macOS menu bar utility for displaying synced lyrics in a floating desktop overlay.

The project started as a local-only MVP, and now includes a Step 2 browser bridge for YouTube Music. The app can prefer real playback metadata from `music.youtube.com` while still falling back to a built-in mock player whenever the bridge is unavailable.

## What It Does

- Runs as a menu bar app using the AppKit lifecycle
- Shows an always-on-top floating lyrics overlay on the desktop
- Receives YouTube Music playback updates through a Chrome extension and native host bridge
- Falls back to a mock player when the bridge is not connected
- Switches synced lyric lines over time
- Provides a SwiftUI settings window for:
  - font size
  - background opacity
  - click-through mode
- Persists settings with `UserDefaults`

## Tech Stack

- Swift
- AppKit
- SwiftUI
- Combine
- Chrome Extension (Manifest V3)
- Chrome Native Messaging
- Python 3 native host
- macOS 13+

## Project Structure

- `Sources/App`
  - App lifecycle, coordinator, and menu bar controller
- `Sources/Domain`
  - Core models and protocols
- `Sources/Infrastructure`
  - Player detectors, bridge server, and `UserDefaults` persistence
- `Sources/Presentation`
  - Overlay window, SwiftUI views, sync engine, and settings UI
- `Sources/Shared`
  - Mock track data and bridge constants
- `BrowserExtension`
  - Chrome extension that scrapes `music.youtube.com`
- `NativeHost`
  - Python native messaging host that forwards playback JSON into the macOS app

## Current Scope

This repository currently includes:

- a native macOS menu bar app
- an AppKit overlay window
- YouTube Music browser bridge plumbing
- mock lyric generation for real and mock tracks
- `UserDefaults`-backed settings persistence

This repository still does not include:

- a real lyrics API
- lyrics caching
- databases
- third-party packages

## Build and Run

1. Open `LyricsOverlay.xcodeproj` in Xcode.
2. Make sure the deployment target is set to macOS 13.0 or later.
3. Build and run the `LyricsOverlay` target.
4. After launch:
   - a menu bar icon appears
   - the lyrics overlay is shown automatically
   - the app waits briefly for browser bridge data
   - if no bridge data arrives, mock playback advances lyric lines over time
   - settings can be opened from the menu bar

## Browser Bridge Setup

### 1. Load the Chrome extension

1. Open `chrome://extensions`
2. Enable `Developer mode`
3. Choose `Load unpacked`
4. Select the `BrowserExtension` folder in this repository
5. Copy the extension ID shown by Chrome

### 2. Make the native host executable

```bash
chmod +x /Users/andie/APP/LyricsOverlay/NativeHost/native_host.py
```

### 3. Register the native messaging host

Create the folder:

```bash
mkdir -p "$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"
```

Create this file:

`~/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.lad0626.lyricsoverlay.bridge.json`

Use this content and replace `YOUR_EXTENSION_ID` with the real Chrome extension ID:

```json
{
  "name": "com.lad0626.lyricsoverlay.bridge",
  "description": "LyricsOverlay native messaging bridge",
  "path": "/Users/andie/APP/LyricsOverlay/NativeHost/native_host.py",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://YOUR_EXTENSION_ID/"
  ]
}
```

### 4. Test the bridge

1. Launch the LyricsOverlay app
2. Open `https://music.youtube.com`
3. Start playback
4. Confirm the overlay switches from pure mock mode to the real track title and artist
5. Confirm the overlay timing follows the browser playback position

## Fallback Behavior

- On startup, the app waits `5` seconds for valid bridge data
- If no bridge data arrives, it starts `MockPlayerDetector`
- If bridge data later appears, the browser bridge becomes the active source immediately
- If bridge data stops for `10` seconds after being active, the app falls back to mock playback again

## Why This Exists

This project is a compile-ready foundation for a desktop lyric utility that can evolve from mock playback into real browser-driven track detection, and later into a full lyrics provider integration.
