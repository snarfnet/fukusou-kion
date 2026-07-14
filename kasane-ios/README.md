# KASANE for iOS

A SwiftUI prototype for discovering place history from your current location. The demo story is set in Asakusa, Tokyo.

## Open on a Mac

1. Install Xcode 15 or later and XcodeGen.
2. Run `xcodegen generate` in this directory.
3. Open `KASANE.xcodeproj`.
4. Select your Apple development team and run on an iPhone or simulator.

Location data is used only by MapKit in the current prototype. The historical content is local sample data; no generative AI or external story API is included.

## Editorial data

The app has two deliberately separate datasets:

- `KASANE/locations.json` is prototype navigation data used to test the nationwide interface.
- `editorial/places.json` is the reviewed source of truth for the 1,000-story collection. The first 300 remain the featured editorial core.

Prototype copy must not be promoted into production automatically. A record appears in `KASANE/published-places.json` only after its editorial status is `publishable` and it passes the publication gate.

Validate the editorial collection and rebuild the app-safe output on Windows PowerShell:

```powershell
.\editorial\validate-editorial.ps1 -BuildPublished
```

See `editorial/EDITORIAL_GUIDE.md` for selection, sourcing, translation, sensitivity, and review rules.
