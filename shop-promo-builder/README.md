# 小さなお店の宣伝ツール

小規模なお店向けの宣伝ページ作成アプリです。
店主さんは管理画面で店名、写真、メニュー、お知らせ、色、アイコンを編集します。
お客さんはQRコードから、お店ごとの公開ページだけを見ます。

## 開発

```bash
npm ci
npm run dev
```

## ビルド

```bash
npm run build
npm run build:ios-bundle
```

## Firebase Hostingで公開する流れ

このアプリでは、会員管理や予約管理のサーバーは持ちません。
店ごとのHTMLページを作り、Firebase Hostingへ静的ファイルとして置きます。

1. 管理画面でお店情報を編集します。
2. 「Firebase公開用データを保存」を押してJSONを保存します。
3. 保存したJSONを使って公開ファイルを作ります。

```bash
npm run build:hosting -- ./komorebi-cafe-firebase-shop-data.json
```

4. `firebase-hosting` フォルダが作られます。
5. Firebase Hostingへ公開します。

```bash
firebase login
firebase init hosting
npm run firebase:deploy
```

公開先URLを指定してQRコードを作る場合は、環境変数を付けます。

```bash
$env:FIREBASE_PUBLIC_URL="https://your-project-id.web.app"
npm run build:hosting -- ./komorebi-cafe-firebase-shop-data.json
```

## Firebase設定

`firebase.json` は追加済みです。
`.firebaserc.example` を `.firebaserc` にコピーし、FirebaseのプロジェクトIDへ変更してください。

```json
{
  "projects": {
    "default": "your-firebase-project-id"
  }
}
```

## 月額運用の考え方

販売価格は月々500円想定です。
含める範囲は、お店ページ作成、QRコード作成、Firebase Hostingでの公開運用です。
会員管理、予約管理、画像管理DB、プッシュ通知は最初の範囲には含めません。

## TestFlight

iOS版は `ios/ShopPromoBuilder` の `WKWebView` ラッパーで動きます。
GitHub Actionsの `.github/workflows/shop-promo-builder-testflight.yml` からTestFlightへアップロードします。

Bundle ID: `com.tokyonasu.shoppromobuilder`
App Store Connect App ID: `6778811541`
