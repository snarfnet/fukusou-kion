# 小さな店の宣伝アプリ

小規模店舗向けの宣伝ツールアプリです。店主は管理画面で店舗情報、画像、メニュー、クーポン、公開URLを編集できます。お客さん側は、お店専用アプリ風の公開ページだけを見ます。

## ビルド

```bash
npm ci
npm run build
```

GitHub Actionsでは `.github/workflows/shop-promo-builder-build.yml` が `shop-promo-builder` をビルドし、`dist` を成果物として保存します。

## TestFlight

`ios/ShopPromoBuilder` は、Webビルドを `WKWebView` で表示するiOSラッパーです。`.github/workflows/shop-promo-builder-testflight.yml` を手動実行すると、Webビルドを同梱したIPAを作り、App Store Connectへアップロードします。

Bundle IDは `com.tokyonasu.shoppromobuilder` です。初回実行前にApple Developer側のBundle IDと、App Store Connect側のアプリレコードを作成してください。今回のASC APIキーでは新規アプリ作成権限がないため、アプリレコード作成後にTestFlightアップロードを実行します。

## 別課金オプション

- A4チラシ作成: 管理画面のメニューやお知らせから印刷用チラシを作成
- 一斉通知: 公開サーバーと通知APIを使った顧客向け通知
- macOS展開: Macでも管理画面が動作

一斉通知とmacOS展開は、サーバー構成やApple Developer設定が必要になるため、基本機能とは分けて扱います。
