# 採寸スナップ (SaisunSnap)

メルカリ・ヤフオク出品用に、服の写真へ寸法線を書き込めるiOSアプリです。

## 機能
- カテゴリ別の採寸項目(トップス/パンツ/スカート/ワンピース/アウター)
- 写真上を2点タップ → 矢印+「ウエスト 76cm」のラベルを配置
- 元画像の解像度のまま書き出し(共有シートから写真へ保存)
- 出品用説明文の自動生成 & コピー

## ビルド手順(Claude Codeでやる場合)

ターミナルでこのフォルダに入り、Claude Codeに以下を頼めばOKです:

```
xcodegen が無ければ brew install xcodegen して、
project.yml から Xcode プロジェクトを生成し、シミュレータでビルドして
```

手動でやる場合:

```bash
brew install xcodegen   # 初回のみ
cd SaisunSnap
xcodegen generate
open SaisunSnap.xcodeproj
```

Xcodeが開いたら、Signing & Capabilities で自分のApple IDのTeamを選び、
シミュレータまたは実機を選んで ⌘R で実行してください。

## ファイル構成
- `SaisunSnap/SaisunSnapApp.swift` … エントリポイント
- `SaisunSnap/Models.swift` … カテゴリ・採寸項目のモデル
- `SaisunSnap/ContentView.swift` … 入力画面・説明文生成
- `SaisunSnap/AnnotatorView.swift` … 寸法線の配置と画像書き出し

## 今後の拡張アイデア
- 採寸データの保存(SwiftData)
- Vision frameworkで服の輪郭検出 → 矢印の自動配置
- メルカリのテンプレに合わせた説明文カスタマイズ
