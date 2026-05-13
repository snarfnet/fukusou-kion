# まとめ・よみきり

2ch/5ch系まとめサイトをRSSで読むiOSアプリのMVPです。

- Bundle ID: `com.tokyonasu.matomeyomikiri`
- App Store Connect App ID: `6769196238`
- AdMob App ID: `ca-app-pub-9404799280370656~4316108976`
- AdMob Bottom Banner Unit ID: `ca-app-pub-9404799280370656/6319455784`
- AdMob Top Banner Unit ID: `ca-app-pub-9404799280370656/2780271265`
- AdMob Detail Banner Unit ID: `ca-app-pub-9404799280370656/4855770262`
- AdMob Inline Banner Unit ID: `ca-app-pub-9404799280370656/3095131881`

## できること

- 初期RSS 1000件の新着記事をまとめて表示
- 配信元の追加、削除、オン/オフ
- 配信元の検索、編集、全オン/全オフ、初期100件へのリセット
- あとで読む保存
- 記事本文はSafari表示
- アプリ内にはRSSの見出し、要約、リンクだけ保存
- 総記事数、今日の記事数、48時間の記事数、サイト別件数を表示
- カテゴリ自動判定
- 期間フィルタ、検索、並び替え
- よく出る語をざっくり集計
- 情報量を上げるコンパクト表示
- 話題クラスタ
- 3分まとめ
- NG疲れワード
- 偏りメーター
- 読後メモ

## 開発メモ

このフォルダはXcodeGen向けの `project.yml` を含みます。Macで開く場合は、`ios/NichanMatome` で次を実行します。

```sh
xcodegen generate
open NichanMatome.xcodeproj
```

初期RSSは `NichanMatome/Models.swift` の `FeedSource.defaults` で管理します。配信元の規約が変わることがあるため、公開前に各サイトのRSS利用条件を確認してください。

1000件のうち一部のRSSはHTTPのみ配信されているため、`Info.plist` と `project.yml` にATS例外を入れています。公開時は不要な例外を削るか、HTTPSで読める配信元に差し替えてください。

## 次に足す候補

- 人気順、既読管理
- AdMobバナー
- App Store用スクリーンショット
- 正式アイコン
- NGワード、ワード通知
- サイト別タブ、時間帯別ランキング
- 読み込み対象の上限設定
