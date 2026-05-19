# DailyAngel / 天使の手紙

毎日、天使語風の短い言葉、日本語、英語のメッセージを届けるSwiftUIアプリです。

## 初回版の機能

- 365日分のメッセージ
- 天使語風、日本語、英語の3段表示
- 今日の小さな行動
- 保存した手紙
- 365日ライブラリ検索
- 毎朝7:30のローカル通知

## プライバシー

通信、ログイン、広告、トラッキングはありません。
保存した手紙と通知設定は端末内に保存します。

## App Store向けの注意

天使語はエノク語に着想を得た雰囲気フレーズです。
厳密な翻訳や未来予測としては表現しません。

推奨表現:

- 天使語風の言葉
- 今日のメッセージ
- 内省のための小さな手紙

避ける表現:

- 必ず当たる
- 本物の天使が命令する
- 未来を断定する

## Build

```bash
cd ios/DailyAngel
xcodegen generate
xcodebuild -project DailyAngel.xcodeproj -scheme DailyAngel -destination "platform=iOS Simulator,name=iPhone 16" build
```

## Submit

GitHub Actionsの `DailyAngel Production` を手動実行します。
App Store Connect側に `com.tokyonasu.dailyangel` のアプリレコードが必要です。

必要なSecrets:

- `DIST_CERT_BASE64`
- `DIST_CERT_PASSWORD`
- `KEYCHAIN_PASSWORD`
- `ASC_API_KEY_CONTENT`
- `DAILYANGEL_APP_ID`
