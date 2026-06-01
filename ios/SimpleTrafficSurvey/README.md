# 簡易歩行者交通量調査

スマホのカメラで通行人を検出し、画面中央のカウントラインを越えた人数を簡易的に数えるiOSアプリです。

## 主な機能

- Visionによる人物検出
- カウントライン通過でIN / OUTを自動加算
- 大きな機械式カウンター風の数字表示
- 手動の+1 / -1補正
- 最近のカウント履歴
- 端末内処理を前提にした設計

## 注意

このアプリは簡易調査向けです。混雑、逆光、夜間、遠距離、手持ち撮影では数え漏れや重複が起きます。三脚などで端末を固定し、通行人がラインを横切る構図で使うと安定します。

## 画像素材

- App icon: `SimpleTrafficSurvey/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
- ImageGen screenshots: `MarketingAssets/Screenshots/`
- App Store 6.7 inch screenshots: `MarketingAssets/AppStoreScreenshots/iphone67/`
