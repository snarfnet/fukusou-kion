# Tsuchinoko Candidate Finder

iOS app for scanning live camera footage and surfacing possible tsuchinoko-style candidates.

The app must not claim that a real tsuchinoko was found. It shows Core ML output as a candidate signal, then asks the user to confirm the scene and footage.

## Features

- On-device camera analysis
- `TsuchinokoCandidate.mlmodel` candidate classification
- Adjustable confidence threshold
- Candidate highlight overlay
- Recent candidate log
- Camera permission guidance

## App Store Positioning

Use wording such as "candidate", "field observation support", and "review needed". Avoid definitive discovery claims.

The current model is a prototype and can confuse branches, roots, hoses, ordinary snakes, and shadows with candidates.

## Build

Generate the Xcode project on macOS with XcodeGen.

```bash
cd ios/TsuchinokoFinder
xcodegen generate
xcodebuild -project TsuchinokoFinder.xcodeproj -scheme TsuchinokoFinder -configuration Release -destination generic/platform=iOS archive -archivePath build/TsuchinokoFinder.xcarchive
```
