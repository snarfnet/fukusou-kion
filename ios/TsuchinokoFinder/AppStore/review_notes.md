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

No account is required. No network connection is required for the core app flow. Camera frames are processed on device.

Known limitation:

The bundled model is a prototype and may classify branches, roots, hoses, ordinary snakes, or shadows as candidates. The UI presents all results as candidates that need human review.
