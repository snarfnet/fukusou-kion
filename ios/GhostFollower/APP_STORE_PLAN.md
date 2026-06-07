# App Store Plan

## 販売形態

- 本体: 有料アプリ
- 価格: 日本ストアで100円に近い価格ポイントを選ぶ
- 追加課金: 非消耗型アプリ内課金

## 追加課金ID

`GhostStore.swift` と App Store Connect の商品IDを合わせます。

- `com.tokyonasu.ghostfollower.pack.shadow`
- `com.tokyonasu.ghostfollower.pack.redmask`
- `com.tokyonasu.ghostfollower.pack.staticnoise`

## 審査メモ

- 動画は端末内で処理します。
- サーバーへ動画を送信しません。
- 写真ライブラリは、書き出した動画の保存にだけ使います。
- ホラー表現はありますが、過度な流血表現は入れていません。

## 次に作ると強いもの

- 人物が複数いる動画でターゲットを選ぶ機能
- 解析後に幽霊位置をキーフレームで手動補正する機能
- 透明PNGや短いループ動画を幽霊素材として読み込む仕組み
- StoreKit Configurationを使ったローカル購入テスト
