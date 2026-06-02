# App Review Notes

App name: ツチノコ候補探知

The app analyzes live camera footage on device and shows possible tsuchinoko-style candidates. It does not claim that a real tsuchinoko was found.

How to test:

1. Open the app on a physical iPhone.
2. Allow camera access.
3. Tap 開始.
4. Point the camera at the ground, grass, a trail, or printed sample imagery.
5. Adjust 候補判定ライン to test the threshold.
6. When confidence exceeds the threshold, the candidate label and log update.

The app also includes an in-app sample flow. Tap サンプル確認 to run the bundled review samples through the same Core ML classifier without needing to aim the camera at an external image.

Review samples:

The repository includes a printable sample sheet at:

```text
AppStore/ReviewSamples/review_sample_sheet.png
```

Print the sheet or show it on another device, then point the app camera at each sample. The two candidate samples should be used to confirm candidate/review-needed behavior. The negative controls are included to show the app does not present every long object as proof.

No account is required. No network connection is required for the core app flow. Camera frames are processed on device.

Known limitation:

The bundled model is a prototype and may classify branches, roots, hoses, ordinary snakes, or shadows as candidates. The UI presents all results as candidates that need human review.
