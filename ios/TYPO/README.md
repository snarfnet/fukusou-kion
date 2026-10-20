# TYPO — 文字の建築家

SwiftUI + Core Text + SceneKitで実装したiOSアプリのソースです。iOS 17以降のiPhone / iPadに対応する構成です。購入処理、広告、アカウント登録はありません。

## Macで起動する

1. `TYPO.xcodeproj` をXcodeで開きます。
2. TYPOターゲットの「Signing & Capabilities」で自分のTeamを選び、Bundle Identifierを変更します。
3. iPhoneシミュレータまたは接続したiPhoneを選び、Runを実行します。
4. Product → Testでテストを実行します。

外部パッケージやXcodeGenのインストールは不要です。フォントも同梱済みです。

コマンドで検証する場合は、`xcrun simctl list devices available` で実在するシミュレータのIDを確認してください。

```sh
xcodebuild -project TYPO.xcodeproj -scheme TYPO \
  -destination 'platform=iOS Simulator,id=YOUR_SIMULATOR_ID' test
```

## 実装した範囲

- ホーム、文字入力、スタジオ、ギャラリー、展示、設定
- 最大12文字の日本語・英数字。未対応文字や輪郭取得失敗を表示
- 同梱Noto Serif CJK JPの輪郭をCore Textで取得し、SCNShapeで押し出し
- Chrome / Bronze / Glass / Paper / Monolith / Neonの6素材
- 厚さ、ベベル、字間、光、背景、回転、拡大、位置調整
- ドラッグ回転、ピンチ拡大、ダブルタップで正面に戻す
- 幅に応じた上下・左右レイアウト、操作パネルの左右入れ替え
- 最大60操作のUndo/Redoと履歴の永続化
- 編集後1.5秒で自動保存、バックグラウンド移行時保存、明示保存時サムネイル生成
- 作品ごとのJSONをatomic書き込み。破損ファイルは保持し、他の作品を読み込み
- 複製保存、作品削除の確認、タイトル非表示ギャラリー
- PNG / 透明PNG / JPEG。1080、2160、縦長、A4比率、4K画像
- システム共有シート。購入制限・透かしなし
- 省電力設定、発熱時の描画品質低下、Reduce Motionへの配慮

## 検証状況と残作業

Windows上でSwift構文解析、モデルの実行テスト、Xcodeプロジェクトの参照・設定チェックを実施しました。iOS SDKがないため、**Xcodeビルド、XCTest、シミュレータ、実機描画は未検証**です。完成・審査提出済みのアプリではありません。IPAの生成とインストールにはMacと署名が必要です。

`TYPOTests`には字形、Oの穴、保存復元、破損データの分離、履歴、透明PNGのテストを用意しています。出荷前に必ずXcodeで実行してください。A・8・永の輪郭品質は画像でも確認する必要があります。

元の仕様から、以下は未実装または簡略化しています。

- Metal / RealityKit独自メッシュではなく、SceneKitの押し出し・三角分割を利用。SceneKitはAppleの旧世代描画基盤であり、長期運用では移行の検討が必要
- Glassは透明材質による近似。物理的な屈折、クリアコート、表面傷、ソフトシャドウ付き床は未実装
- ベベルは字形の破綻を抑えるため0〜5に制限。複雑な字形での交差は実機検証が必要
- 字形単位の選択・素材・グループ化、アーチ、行間、レイヤー、2本指移動は未実装。全体の位置はスライダーで調整
- フォントは1種、素材は6種。専用コレクション画面と8種の造形プリセットは未実装
- MP4 / HEIC / 透過動画は未実装
- 展示はスロー回転。終了ボタンの自動非表示・照明変化は未実装
- 日本語UI。英語UI、BGM、触覚設定は未実装
- 特定の「iPhone Duo」や開閉角度APIは仮定していない。公開された画面サイズによる適応レイアウトのみ
- 大画像生成はメインスレッドから同期実行。実機で速度とメモリを測り、必要に応じて書き出し専用キューへ移す
- 自動保存直前の強制終了では直近1.5秒分を失う可能性あり。ストレージ不足時はエラー表示

## 実機での確認

- 「永 / A / 8 / O」を生成し、穴、曲線、最大ベベル、厚さ0で破綻しないか
- 12文字、長い作品名、最大の文字サイズ、VoiceOver、Reduce Motion
- 縦横切り替え、広いウィンドウ、編集途中のバックグラウンド移行
- 保存、終了、再起動、取り消し・やり直し、複製、削除
- すべての画像比率、透明PNGのアルファ、JPEG背景、共有のキャンセル
- 低電力・発熱・ストレージ不足・連続4K書き出し。60/30fpsは未計測

## ライセンスと参考資料

フォントはNoto Serif CJK JP Regular、SIL Open Font License 1.1です。全文をアプリ内設定と `TYPO/Resources/OFL.txt` に収録しています。フォントの改変はしていません。

- フォント配布元: https://github.com/notofonts/noto-cjk
- Apple Core Text: https://developer.apple.com/documentation/coretext
- 字形輪郭取得: https://developer.apple.com/documentation/coretext/ctfontcreatepathforglyph(_:_:_:)
- SceneKit押し出し: https://developer.apple.com/documentation/scenekit/scnshape/extrusiondepth

作品のJSONには文字と編集パラメータだけを保存します。フォント輪郭の外部配布は行いません。ネットワーク通信・アクセス解析SDK・StoreKitは含めていません。
