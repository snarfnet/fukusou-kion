# Voiceprint Installation

声だけで抽象アートを生成するiOS MVPです。録音音声は保存せず、波形、ピッチ、リズム、無音率などの特徴量から作品を描きます。

## MVP

- 5秒録音
- ライブ音量・ピッチ表示
- Canvasによるジェネラティブアート生成
- PNG書き出し
- OpenSea向けmetadata JSON書き出し
- 作品ギャラリー
- App Store有料販売を想定したTestFlight準備

## OpenSea連携

アプリ内の「OpenSeaを開く」は確認導線です。実際のmintは次の流れで実装します。

1. PNGをIPFSへアップロード
2. metadata JSONの`image`を`ipfs://...`へ差し替え
3. ERC-721またはERC-1155でmint
4. OpenSeaでmetadataを読み込み

秘密鍵やOpenSea APIキーをiOSアプリに直置きしないでください。本番ではサーバー側で署名・IPFSアップロードを扱います。

## 800円販売

アプリ本体を800円で売る場合、iOSコード側の課金処理は不要です。App Store Connectで価格を設定します。

- Paid Apps Agreementを有効化
- Pricing and Availabilityで日本向け価格を800円相当に設定
- TestFlight配信中はテスターからアプリ代金は取りません

Apple公式:

- https://developer.apple.com/help/app-store-connect/manage-app-pricing/set-a-price
- https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/

## TestFlight手順

Macで作業してください。

```sh
cd ios/VoiceprintInstallation
xcodegen generate
open VoiceprintInstallation.xcodeproj
```

Xcodeで以下を確認します。

- Bundle ID: `com.tokyonasu.voiceprintinstallation`
- Team: 自分のApple Developer Team
- Signing: Automatic
- Build numberを提出ごとに更新

提出:

1. Xcodeで`Any iOS Device`を選択
2. `Product > Archive`
3. Organizerから`Distribute App`
4. `App Store Connect`へアップロード
5. App Store ConnectのTestFlightで内部テスターを追加
6. 外部テスターへ出す場合はBeta App Reviewへ提出

## GitHub ActionsでTestFlightへアップロード

専用workflow:

- `.github/workflows/voiceprint-ios-build.yml`

必要なGitHub Secrets:

- `ASC_KEY_ID`
- `ASC_ISSUER_ID`
- `ASC_PRIVATE_KEY` または `ASC_API_KEY_CONTENT`
- 任意: `DIST_CERT_BASE64` または `IOS_DISTRIBUTION_P12_BASE64`
- 任意: `DIST_CERT_PASSWORD` または `IOS_DISTRIBUTION_P12_PASSWORD`
- 任意: `KEYCHAIN_PASSWORD`

実行:

```sh
gh workflow run "Voiceprint iOS Build" --ref codex/trouble-navi-testflight -f upload_testflight=true
```

このworkflowはApp Store Connectのアプリ登録、配布証明書、Provisioning Profile、Archive、IPA export、App Store Connect upload、TestFlight処理待ちまで行います。App Store審査提出はしません。

## 次に足す機能

- WalletConnect
- IPFSアップロード用バックエンド
- mint用スマートコントラクト
- OpenSea listing導線
- Core ML Stable Diffusionモード
