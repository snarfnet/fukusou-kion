# 禅パワー

SwiftUIで作る、広告付きの禅習得アプリMVPです。

## 入っている機能

- 今日の一座
- 坐禅タイマー
- 呼吸ガイド
- 初心者向けレッスン
- 禅語カード
- 実践記録
- AdMobバナー広告
- 画像付きのやさしい説明

## Xcodeで開く

Macで次のどちらかを使います。

```bash
cd ios/ZenPower
xcodegen generate
open ZenPower.xcodeproj
```

XcodeGenを使わない場合は、Xcodeで新規iOS Appを作り、`ZenPower` フォルダ内のSwiftファイルと `Assets.xcassets`、`Resources` をターゲットへ追加してください。

## 広告ID

App IDとバナー広告ユニットIDは本番IDを設定済みです。広告はバナーのみ使います。

- `GAD_APPLICATION_IDENTIFIER`
- `GAD_BANNER_AD_UNIT_ID`

## 画像素材

`imagegen` で生成した説明画像を `Assets.xcassets` に入れています。

- `zen-posture`: 坐禅の姿勢
- `zen-breath`: 呼吸の流れ
- `zen-thoughts`: 雑念に気づいて戻る流れ
- `zen-journal`: 実践記録

画像の中に文字は入れていません。説明文はSwiftUI側で表示するので、読みやすさと修正しやすさを保てます。

## 次にやること

- App Store用の1024pxアイコンを作り込む
- App Tracking TransparencyとUMP同意フォームを追加する
- レッスン本文を増やす
- App Store説明文、プライバシーポリシー、スクリーンショットを用意する
