# CellArtisan / たまにいるエクセル職人

画像をExcelセルアートに変換するiOSアプリです。写真やイラストを読み込み、セルの塗りつぶし色だけで作った `.xlsx` を書き出します。

## 実装済み

- 写真ライブラリから画像を選択
- 横セル数の調整
- 色数の調整
- Excel上のセルサイズ調整
- グリッド線の表示切り替え
- セルアートプレビュー
- `.xlsx` 書き出し
- 共有シートでExcel/Numbers/Filesへ送信
- 仮AppIcon
- PrivacyInfo

## 仕組み

1. 画像の向きを補正
2. 指定した横セル数に縮小
3. よく使われる色を抽出
4. 各ピクセルを近い色へ減色
5. セルごとに塗りつぶしスタイルを持つExcel XMLを生成
6. ZIPFoundationで `.xlsx` として圧縮

## Xcodeで開く

このプロジェクトはXcodeGen形式です。

```sh
cd ios/CellArtisan
xcodegen generate
open CellArtisan.xcodeproj
```

## GitHub Actions / TestFlight

`.github/workflows/cell-artisan-testflight.yml` で、App Store Connectアプリ作成、署名、Archive、TestFlightアップロードまで行います。

必要なGitHub Secrets:

- `ASC_KEY_ID`
- `ASC_ISSUER_ID`
- `ASC_PRIVATE_KEY` または `ASC_API_KEY_CONTENT`
- `IOS_DISTRIBUTION_P12_BASE64` と `IOS_DISTRIBUTION_P12_PASSWORD` は任意。未設定ならworkflow内で配布証明書を作成します。
- `CELL_ARTISAN_APP_ID` は任意。App Store Connect側でアプリ作成済みの場合に設定します。

手動実行はGitHub Actionsの `CellArtisan TestFlight Upload` からできます。`codex/cell-artisan-testflight` ブランチへpushしても走ります。

## 次に入れると強い機能

- 書き出し前のファイル名変更
- 背景透過PNG対応
- 文字・ロゴ専用モード
- QRコードをセル化
- Excel内に元画像と設定メモを別シートで保存
- 色パレットの手動編集
- A4印刷用の設計図PDF

## 販売方針

初期価格は日本ストア100円を想定しています。価格設定はApp Store Connectの価格と配信状況で行います。
