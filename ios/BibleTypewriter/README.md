# 聖書のことば

口語訳、WEB、KJVを静かなタイポライター表示で読むiOSアプリです。

## 構成

- `BibleTypewriter/Views`: 画面とタイポライター制御
- `BibleTypewriter/Services`: 聖書本文の取得
- `BibleTypewriter/Models`: 書名、翻訳、背景カテゴリ
- `BibleTypewriter/Backgrounds`: 生成背景80枚
- `BibleTypewriter/Assets.xcassets`: アプリアイコン

## 本文

- 口語訳: `jpn.bible` から章単位で取得
- WEB / KJV: The Bible APIから章単位で取得

通信できない時は短いサンプル本文を表示します。

## ビルド

macOS上で以下を実行します。

```bash
cd ios/BibleTypewriter
xcodegen generate
xcodebuild build -scheme BibleTypewriter -destination 'generic/platform=iOS'
```
