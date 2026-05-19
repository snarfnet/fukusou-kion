# 禅パワー 提出チェックリスト

## GitHub Secrets

`ZenPower TestFlight Upload` を動かす前に、リポジトリの GitHub Secrets に入れます。

- `APPSTORE_API_KEY_ID`: App Store Connect APIキーのKey ID
- `APPSTORE_API_ISSUER_ID`: Issuer ID
- `APPSTORE_API_PRIVATE_KEY`: `AuthKey_XXXX.p8` の中身

APIキーは App Store Connect の `Users and Access > Integrations > App Store Connect API` で作ります。権限は App Manager 以上を推奨します。

## App Store Connect

- Bundle ID: `com.tokyonasu.zenpower`
- SKU案: `zenpower-ios`
- Primary language: Japanese
- 追加言語: English
- Category案: Lifestyle
- Age Rating案: 4+
- Sign-in: なし
- In-App Purchase: なし
- Ads: あり、バナーのみ

## 素材

- アイコン: `MarketingAssets/AppIcon/ZenPower-AppIcon-1024.png`
- 日本語スクショ: `MarketingAssets/Screenshots/iphone_69/ja`
- 英語スクショ: `MarketingAssets/Screenshots/iphone_69/en`
- 提出文言: `AppStore/APP_STORE_SUBMISSION.md`

## プライバシー

アプリ本体はアカウント、連絡先、位置情報を使いません。坐禅ログは端末内の `UserDefaults` に保存します。

AdMobを使うため、App Storeのプライバシー回答では広告関連のデータ利用を確認してください。Googleの案内に沿って、必要な地域ではUMP同意フォームを表示します。

## アップロード

1. App Store Connectで新規アプリを作る。
2. GitHub Secretsを設定する。
3. GitHub Actionsの `ZenPower TestFlight Upload` を手動実行する。
4. App Store ConnectのTestFlightで処理完了を待つ。
5. スクショ、説明文、プライバシー回答、審査メモを入れる。
6. 内部テストで起動、バナー、坐禅タイマー、記録、日英表示を確認する。
7. 問題なければ審査へ提出する。

## 審査メモ案

禅パワーは、坐禅タイマー、呼吸ガイド、初心者向けレッスン、実践記録を提供するアプリです。ログインは不要です。広告はバナーのみで、坐禅中に全画面広告は表示しません。
