# Submission Checklist

## App Store Connect

- Create the app manually if the API key cannot create apps.
- App name: `ツチノコ候補探知`
- Bundle ID: `com.tokyonasu.tsuchinokofinder`
- SKU: `tsuchinoko-finder-ios`
- Primary locale: Japanese
- Price: choose after product decision.

## Metadata

- Use `metadata_ja.md` for the Japanese description.
- Use `privacy_ja.md` for privacy notes.
- Use `review_notes.md` for App Review notes.

## Screenshots

Use the 6.7-inch screenshots in:

```text
MarketingAssets/Screenshots/iphone67/
```

Files:

- `iphone67_01_main.png`
- `iphone67_02_threshold.png`
- `iphone67_03_log.png`

## TestFlight Upload

Run the GitHub Actions workflow:

```text
TsuchinokoFinder TestFlight
```

If the app was created manually, pass the App Store Connect app ID as the workflow `appId` input, or save it as the `TSUCHINOKO_FINDER_APP_ID` repository secret.

## Review Risk

Do not market the app as proof of a real tsuchinoko discovery. Keep wording to `候補`, `要確認`, and observation support.
