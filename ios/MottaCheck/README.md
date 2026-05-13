# 忘れ物ゼロ

外出前の持ち物チェックアプリです。仕事、学校、旅行、ジム、病院のテンプレートからリストを作り、出発前に通知できます。

## 主な機能

- 持ち物リスト作成、編集、並び替え
- テンプレート選択
- 今日使うリストと進捗表示
- 朝と出発前の通知
- よく使うリスト保存
- 忘れやすい持ち物ランキング
- AdMobバナー広告

## 技術

- SwiftUI
- SwiftData
- UserNotifications
- AppStorage
- 広告表示枠

## セットアップ

```sh
xcodegen generate
open MottaCheck.xcodeproj
```

AdMobの本番IDが用意できたら、`AdService.swift` をSDK実装に差し替えられます。提出用MVPでは署名を安定させるため、広告枠はネイティブ表示です。

## App Store Connect

- App ID: `6769013627`
- Bundle ID: `com.tokyonasu.mottacheck`
- SKU: `MottaCheck2026`
- Primary Locale: `ja`
