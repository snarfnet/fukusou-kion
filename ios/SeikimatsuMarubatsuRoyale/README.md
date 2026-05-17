# 世紀末マルバツロワイヤル

SwiftUI MVP for TestFlight.

## Local build on macOS

```bash
brew install xcodegen
xcodegen generate
xcodebuild -project SeikimatsuMarubatsuRoyale.xcodeproj -scheme SeikimatsuMarubatsuRoyale -destination "generic/platform=iOS" build
```

## TestFlight

GitHub Actions workflow: `.github/workflows/seikimatsu-marubatsu-testflight.yml`
