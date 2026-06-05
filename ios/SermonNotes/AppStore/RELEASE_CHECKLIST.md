# 教会ノート リリース手順

## GitHub Secrets

リポジトリに次を登録します。

- `ASC_KEY_ID`
- `ASC_ISSUER_ID`
- `ASC_PRIVATE_KEY` または `ASC_API_KEY_CONTENT`
- `SERMON_NOTES_APP_ID` 任意。App Store Connectで作成済みなら入れます。

## ビルド確認

GitHub Actionsで `SermonNotes iOS Build` を手動実行します。

## TestFlightアップロード

GitHub Actionsで `SermonNotes TestFlight Upload` を手動実行します。

- version: `1.0`
- build_number: 空欄でOK
- app_id: App Store ConnectのApp IDが分かる場合だけ入力

## App Store Connect設定

- 名前: 教会ノート
- SKU: `sermon-notes-ios`
- Bundle ID: `com.tokyonasu.sermonnotes`
- 価格: 日本は100円に近い価格ポイントを選びます
- カテゴリ: Productivity または Lifestyle
- 広告: なし
- トラッキング: なし
- データ収集: なし

## 説明文案

教会ノートは、礼拝メモ、説教メモ、聖書箇所、祈りの課題をまとめて残せるシンプルなノートアプリです。教会で聞いた言葉をすぐに書き、日付・牧師名・教会名・聖書箇所で整理できます。

## 審査前チェック

- アイコンが指定画像になっている
- 新規メモを保存できる
- 検索で本文、牧師名、教会名、聖書箇所を探せる
- 祈りの課題をチェックできる
- 外部通信や広告SDKが入っていない
