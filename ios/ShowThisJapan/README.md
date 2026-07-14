# Show This Japan

訪日旅行者が、日本語の会話カードを相手に見せて意思を伝える iOS 17+ アプリです。カード、検索、音声、お気に入り、履歴、緊急プロフィール、110/119 の発信確認、現在地表示がオフライン中心で動きます。個人情報を外部へ送信しません。

## 起動方法

1. macOS に Xcode と [XcodeGen](https://github.com/yonaskolb/XcodeGen) を入れます。
2. このフォルダーで `xcodegen generate` を実行します。
3. `ShowThisJapan.xcodeproj` を開き、iOS 17 以上のシミュレーターまたは実機で実行します。

位置情報と電話発信は実機で確認してください。位置情報は「Current Location」でボタンを押したときだけ要求します。

TestFlightへの署名・アップロード手順は `TESTFLIGHT.md` を参照してください。

## 構成

- `Models.swift`: カード、カテゴリー、緊急プロフィール
- `AppViewModel.swift`: JSON 読み込み、検索、端末保存
- `Services.swift`: 音声読み上げ、位置情報
- `*Views.swift`: SwiftUI 画面
- `Resources`: 10カテゴリー、150フレーズのローカル JSON
- `ShowThisJapanTests`: デコード、検索、履歴、お気に入りのテスト

150フレーズを収録しています。基本データは `phrase_cards.json`、追加データは `phrase_cards_expansion.json` に分けています。
