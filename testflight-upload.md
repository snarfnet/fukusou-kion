# TestFlight Upload Handoff

## Current Status

This project is now prepared as a Capacitor iOS app.

- Web app: React + Vite
- iOS wrapper: `ios/App/App.xcodeproj`
- App name: `熱中症予防サポート`
- Temporary Bundle ID: `com.heatguard.app`
- Version: `1.0`
- Build: `1`
- AdMob app id: `ca-app-pub-9404799280370656~9293420712`
- AdMob banner unit id: `ca-app-pub-9404799280370656/6667257375`

## What Still Blocks Direct Upload Here

This machine is Windows. TestFlight upload needs a signed iOS archive, which requires macOS with Xcode or a macOS CI runner.

Apple's official upload paths are Xcode, Swift Playgrounds, Transporter, or Transporter CLI with App Store Connect API authentication.

## Needed From Apple Developer Account

- Apple Developer Program membership
- App Store Connect app record
- Registered Bundle ID
- Team ID
- Signing certificate and provisioning profile, or automatic signing in Xcode
- App Store Connect role with upload permission

If the real Bundle ID is not `com.heatguard.app`, change it in Xcode before archiving.

## Mac Upload Steps

1. Copy this project folder to a Mac.
2. Install dependencies:

```bash
npm install
```

3. Build and sync:

```bash
npm run ios:sync
```

4. Open Xcode:

```bash
npm run ios:open
```

5. In Xcode:

- Select `App` target.
- Set Team to your Apple Developer team.
- Confirm Bundle Identifier.
- Confirm Version and Build.
- Select `Any iOS Device`.
- Run `Product > Archive`.

6. In Organizer:

- Select the archive.
- Click `Distribute App`.
- Choose `App Store Connect`.
- Upload.

7. In App Store Connect:

- Wait for processing.
- Open TestFlight.
- Add internal testers.
- Add external testing details if needed.

## GitHub Actions Upload

Workflow file:

```text
.github/workflows/testflight.yml
```

The workflow builds on `macos-latest`, archives the Capacitor iOS app, exports an IPA, and uploads it with `xcrun altool`.

Apple documents build uploads through Xcode, Transporter, App Store Connect API, and `altool`.

Required GitHub repository secrets:

```text
APPLE_TEAM_ID
IOS_CERTIFICATE_P12_BASE64
IOS_CERTIFICATE_PASSWORD
IOS_PROVISION_PROFILE_BASE64
APP_STORE_CONNECT_KEY_ID
APP_STORE_CONNECT_ISSUER_ID
APP_STORE_CONNECT_API_KEY_P8
```

### Bundle ID

Desired Bundle ID:

```text
com.heatguard.app
```

This still must be registered in Apple Developer before the workflow can sign and upload.

### Creating Base64 Secrets On macOS

Certificate:

```bash
base64 -i ios_distribution.p12 | pbcopy
```

Provisioning profile:

```bash
base64 -i HeatGuard_AppStore.mobileprovision | pbcopy
```

Paste each copied value into the matching GitHub secret.

### Running The Workflow

1. Push this repo to GitHub.
2. Add the secrets above in repository settings.
3. Open Actions.
4. Run `TestFlight`.
5. Increase `build_number` every upload.

## Safety Notes

- Do not show interstitial or rewarded ads near emergency actions.
- Keep AdMob as a banner after safety actions only.
- Use test ad units during development if a live SDK is connected before release.
