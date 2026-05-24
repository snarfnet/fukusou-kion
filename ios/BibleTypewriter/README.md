# 聖書のことば

WEB / KJV を静かなタイポライター表示で読む iOS アプリです。口語訳は収録していません。

## 構成

- `BibleTypewriter/Views`: 画面とタイプライター制御
- `BibleTypewriter/Services`: WEB / KJV 本文の取得
- `BibleTypewriter/Models`: 書名、翻訳、背景カテゴリ
- `BibleTypewriter/Backgrounds`: 生成背景80枚
- `BibleTypewriter/Assets.xcassets`: アプリアイコン

## 本文

- WEB / KJV: The Bible API から章単位で取得

通信できない時は短いサンプル本文を表示します。

## ビルド

macOS上で以下を実行します。

```bash
cd ios/BibleTypewriter
xcodegen generate
xcodebuild build -scheme BibleTypewriter -destination 'generic/platform=iOS'
```
