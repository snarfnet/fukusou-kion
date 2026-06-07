# Ghost Follower

iOS向けのホラー動画加工MVPです。動画を読み込み、Visionで人物を検出し、幽霊レイヤーを追従させて書き出します。

## できること

- 動画読み込み
- 人物検出と簡易トラッキング
- 幽霊の種類、位置、サイズ、透明度の調整
- 幽霊入り動画の書き出し
- StoreKit用の追加パック導線

## 作り方

```bash
cd ios/GhostFollower
xcodegen generate
open GhostFollower.xcodeproj
```

App Store Connectで追加課金を使う場合は、`GhostStore.swift` の product ID と App Store Connect 側の商品IDを合わせてください。
