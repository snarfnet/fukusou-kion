# ツチノコを探す！

iOS app for scanning live camera footage and surfacing possible tsuchinoko-style candidates.

The app must not claim that a real tsuchinoko was found. It shows a candidate signal, then asks the user to confirm the scene and footage.

## Features

- On-device camera analysis
- Candidate classification model
- Adjustable confidence threshold
- Candidate highlight overlay
- Recent candidate log
- Camera permission guidance
- Printable review sample sheet for App Review and demos

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

## TestFlight

GitHub Actions workflow:

```text
TsuchinokoFinder TestFlight
```

The workflow can archive and export the IPA. If App Store Connect app creation is blocked by API-key permissions, create the app manually in App Store Connect first.

Use these values:

- Name: `ツチノコを探す！`
- Bundle ID: `com.tokyonasu.tsuchinokofinder`
- SKU: `tsuchinoko-finder-ios`
- Primary locale: Japanese

After manual creation, rerun the workflow with the `appId` input set to the App Store Connect app ID. The same value can also be stored as the `TSUCHINOKO_FINDER_APP_ID` repository secret.

Latest verified run:

- Run ID: `26794305145`
- Result: archive and IPA export succeeded
- Artifact: `TsuchinokoFinder-ipa`
