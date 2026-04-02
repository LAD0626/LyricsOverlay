# LyricsOverlay

LyricsOverlay is a macOS menu bar utility MVP for displaying synced lyrics in a floating desktop overlay.

This version is intentionally local-only and uses mock data to validate the app shell, overlay behavior, settings flow, and persistence without relying on any network requests or third-party services.

## What It Does

- Runs as a menu bar app using the AppKit lifecycle
- Shows an always-on-top floating lyrics overlay on the desktop
- Simulates playback progress with a mock player
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
- macOS 13+

## Project Structure

- `Sources/App`
  - App lifecycle, coordinator, and menu bar controller
- `Sources/Domain`
  - Core models and protocols
- `Sources/Infrastructure`
  - Mock player and `UserDefaults` persistence
- `Sources/Presentation`
  - Overlay window, SwiftUI views, sync engine, and settings UI
- `Sources/Shared`
  - Mock track and lyric data

## MVP Scope

This repository does not include:

- YouTube Music integration
- external APIs
- Chrome extensions
- browser detection
- network requests
- databases
- third-party packages

## Build and Run

1. Open `LyricsOverlay.xcodeproj` in Xcode.
2. Make sure the deployment target is set to macOS 13.0 or later.
3. Build and run the `LyricsOverlay` target.
4. After launch:
   - a menu bar icon appears
   - the lyrics overlay is shown automatically
   - mock playback advances lyric lines over time
   - settings can be opened from the menu bar

## Why This Exists

This project is a compile-ready MVP skeleton for validating the desktop utility architecture before integrating any real music source or lyrics provider.
