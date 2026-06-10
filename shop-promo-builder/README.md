# 小さな店の宣伝アプリ

小規模店舗向けの宣伝ツールアプリです。店主は管理画面で店舗情報、画像、メニュー、クーポン、公開URLを編集できます。お客さん側は、お店専用アプリ風の公開ページだけを見ます。

## ビルド

```bash
npm ci
npm run build
```

GitHub Actionsでは `.github/workflows/shop-promo-builder-build.yml` が `shop-promo-builder` をビルドし、`dist` を成果物として保存します。

## 別課金オプション

- A4チラシ作成: 管理画面のメニューやお知らせから印刷用チラシを作成
- 一斉通知: 公開サーバーと通知APIを使った顧客向け通知
- macOS展開: 管理画面をMac用アプリとして配布

一斉通知とmacOS展開は、サーバー構成やApple Developer設定が必要になるため、基本機能とは分けて扱います。
