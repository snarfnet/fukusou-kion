# うちの子カルテ

ペットの食事、体重、薬、通院、写真、家族共有をまとめるiPhone向けSwiftUIアプリです。

## 画面

- ホーム: 今日の記録、思い出、家族タスク
- 記録: 食事、薬、体重、症状、通院、写真、散歩
- カレンダー: 通院、ワクチン、保険更新の予定追加
- 健康管理: 体重グラフ、病院用PDF、AI健康メモ、保険、病院情報
- 思い出: アルバム、迷子QR、家族共有、追加パック導線

## 料金案

- Plus 買い切り: 1,480円
- AI健康メモ 50回: 300円
- 病院用PDFテンプレ追加: 300円
- 成長アルバム書き出し: 500円
- 思い出カードテーマ: 160円から300円

## Macで開く

```bash
cd ios/PetCareOS
brew install xcodegen
xcodegen generate
open PetCareOS.xcodeproj
```

Xcodeで`PetCareOS`スキームを選び、iPhoneシミュレータで実行します。

## GitHubでビルド

`.github/workflows/petcareos-ios-build.yml`を追加済みです。GitHubへpushすると、XcodeGenでプロジェクトを生成し、iPhoneシミュレータ向けにDebugビルドします。

App Store提出用の署名ビルドは、Apple Developerの証明書、Provisioning Profile、App Store Connect APIキーをGitHub Secretsへ入れてから別ワークフローで組みます。
