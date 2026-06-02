# App Review Notes

App name: ツチノコを探す！

The app analyzes live camera footage on device and shows possible tsuchinoko-style candidates. It does not claim that a real tsuchinoko was found.

How to test:

1. Open the app on a physical iPhone.
2. Allow camera access.
3. Tap 開始.
4. Point the camera at the ground, grass, a trail, or printed sample imagery.
5. Adjust 候補判定ライン to test the threshold.
6. When the app sees repeated candidate-like signals above the threshold, the candidate label and log update.

Review samples:

The repository includes a printable sample sheet at:

```text
AppStore/ReviewSamples/review_sample_sheet.png
```

Print the sheet or show it on another device, then point the app camera at each sample. The two candidate samples should be used to confirm candidate/review-needed behavior. The negative controls are included to show the app does not present every long object as proof.

No account is required. No network connection is required for the core app flow. Camera frames are processed on device.

Known limitation:

The bundled model is a prototype. The UI treats results as candidate signals that need human review, and the app requires repeated candidate-like signals before logging a candidate.
