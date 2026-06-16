# APNG Sticker Studio

1枚の画像から、LINE Creators Market向けのAPNGスタンプ素材を作るiOSアプリです。

## MVP

- PhotosUIで画像を読み込み
- 320 x 270pxのAPNGフレームを生成
- Pop / Shake / Bounce / Float / Sparkle / Heart / Confetti
- 強さ、速さ、フレーム数、ループ数を調整
- 透明背景、白背景、淡い青背景を選択
- APNGを書き出して共有
- LINE向けの簡易チェックを表示
- 画像処理は端末内だけで完結

## Build

このフォルダでXcodeGenを実行してから、生成されたXcodeプロジェクトを開きます。

```sh
xcodegen generate
open APNGStickerStudio.xcodeproj
```

## App Storeメモ

- 販売価格: 300円買い切り
- カテゴリ: Photo & Video
- アプリ内課金なし
- 画像はサーバーへ送信しない
- LINE公式アプリに見える表現は避ける

## 初回版で残す作業

- App Iconを1024px PNGで追加
- 実機でAPNGの再生確認
- LINE Creators Marketへのアップロード確認
- App Store用スクリーンショットを作成
