# Submission Checklist

## App Store Connect

- Create the app manually if the API key cannot create apps.
- App name: `ツチノコを探す！`
- Bundle ID: `com.tokyonasu.tsuchinokofinder`
- SKU: `tsuchinoko-finder-ios`
- Primary locale: Japanese
- Price: JPY 100.

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

## Review Samples

Use the printable review sample sheet when recording a demo video or helping App Review test the camera flow:

```text
AppStore/ReviewSamples/review_sample_sheet.png
```

The sheet includes two candidate samples and two negative controls. Show clearly that the app presents results as candidate/review-needed signals, not proof.

## Demo Video

If App Review asks for a demo video, record on a physical iPhone:

1. Open the app.
2. Allow camera access.
3. Tap `開始`.
4. Point the camera at `review_sample_sheet.png` on paper or another screen.
5. Show the confidence value, threshold slider, and candidate log.
6. Show the review note that results are candidates, not a definitive discovery.

## TestFlight Upload

Run the GitHub Actions workflow:

```text
TsuchinokoFinder TestFlight
```

If the app was created manually, pass the App Store Connect app ID as the workflow `appId` input, or save it as the `TSUCHINOKO_FINDER_APP_ID` repository secret.

## Review Risk

Do not market the app as proof of a real tsuchinoko discovery. Keep wording to `候補`, `要確認`, and observation support.
