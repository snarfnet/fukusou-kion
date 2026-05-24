# 清掃の心得 iOS

SwiftUI版の「清掃の心得」です。広告なし、通信なし、データ収集なしのライフスタイルアプリとして提出する想定です。

## 内容

- 豆知識10000件をアプリ内で生成
- タイプライター風の豆知識表示
- 今日の風水掃除アドバイス
- ホウキ針タイマー
- アラーム音
- App Icon / Timer Dial / Broom Hand assets
- Privacy manifest
- App Store metadata draft
- Marketing screenshots

## Macでのビルド

```bash
cd ios/SeisoNoKokoroe
brew install xcodegen
xcodegen generate
open SeisoNoKokoroe.xcodeproj
```

Xcodeで Signing & Capabilities を確認し、Team が `83VGKGSQUH` になっていることを確認してください。

## Archive

```bash
cd ios/SeisoNoKokoroe
./scripts/build_and_upload.sh
```

生成されたIPAは `build/export` に出ます。

## App Store Connect

- Bundle ID: `com.tokyonasu.seisonokokoroe`
- Category: Lifestyle
- Age Rating: 4+
- Privacy: Data Not Collected
- Encryption: Non-exempt encryption not used

メタデータは `APP_STORE_METADATA.md` を使ってください。
スクリーンショットは `MarketingAssets/Screenshots` にあります。
