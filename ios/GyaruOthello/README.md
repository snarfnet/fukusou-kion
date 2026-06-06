# ギャルオセロ iOS

Web版のギャルオセロを `WKWebView` で内包したiPhone/iPad向けアプリです。

## 生成

```sh
cd ios/GyaruOthello
xcodegen generate
open GyaruOthello.xcodeproj
```

## 提出の流れ

1. Xcodeで `Any iOS Device` を選ぶ
2. `Product > Archive`
3. OrganizerからApp Store Connectへアップロード
4. ASCでアプリレコードを作る
5. `python scripts/prepare_asc.py`
6. `python scripts/upload_screenshots.py`
7. 審査情報とビルド選択を確認して提出

Windows上ではXcodeのArchiveとTransporterアップロードは実行できません。
