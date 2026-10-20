# TYPO — 文字の建築家

日本語や英数字を立体作品にするiOSアプリです。SwiftUI、Core Text、SceneKitで実装しています。iOS 17以降のiPhone / iPadに対応します。アプリ内課金、広告、アカウント登録、透かしはありません。全素材・詳細編集・4K・動画出力を追加購入なしで使えます。

## 使い方

1. ホームの「文字をつくる」から最大12文字・3行まで入力します。
2. スタジオで素材、厚さ、ベベル、字間、行間、アーチ、照明、背景を調整します。
3. 1本指で回転、2本指で移動、ピンチで拡大します。文字の長押しで個別選択、ダブルタップで構図を戻します。
4. 「文字ごと」で移動・回転・サイズ・重なり順・グループ化を調整します。素材は選択中の文字にも適用できます。
5. 保存するとギャラリーから再編集できます。「作品」タブから書き出し・共有・展示を開きます。

編集は1.5秒後とバックグラウンド移行時に自動保存します。明示保存ではサムネイルも更新します。取り消し・やり直しは60操作まで作品と一緒に保持します。

## 素材と書き出し

素材はChrome / Bronze / Glass / Paper / Monolith / Neon。コレクションにはMonolith / Chrome / Museum / Glass / Bronze / Paper / Neon / Architecturalの8プリセットを収録しています。

PBRの粗さ・金属度・クリアコート・表面傷、3灯の照明、反射環境、床の影、5背景を調整できます。Glassは透明素材による屈折風の表現です。

- PNG、透明PNG、JPEG、HEIC（対応する端末のみ）
- 1080 × 1080、2160 × 2160、1080 × 1920、2480 × 3508、3840 × 2160
- 30fpsの回転MP4：5・10・15秒。動画ではA4比率を除く4サイズ
- iOS標準の共有シート。共有先は利用者が選びます

書き出し中のキャンセル、バックグラウンド移行、メモリ警告を処理します。透過動画は提供していません。

## ビルド

外部SwiftパッケージやXcodeGenは不要です。フォントと音源を同梱しています。

`TYPO.xcodeproj`をXcodeで開き、TYPOスキームとiOSシミュレータを選んで実行します。

```sh
xcodebuild test -project TYPO.xcodeproj -scheme TYPO \
  -destination 'platform=iOS Simulator,id=YOUR_SIMULATOR_ID' \
  CODE_SIGNING_ALLOWED=NO
```

実機や配布用ビルドにはApple Developerの署名が必要です。このプロジェクトのBundle IDは`com.tokyonasu.typo`です。

GitHubの専用ブランチ`codex/typo-testflight`、`ios/TYPO`に同じソースを配置しています。

- [GitHubソース](https://github.com/snarfnet/fukusou-kion/tree/codex/typo-testflight/ios/TYPO)
- [iPhone / iPad検証](https://github.com/snarfnet/fukusou-kion/actions/workflows/typo-ci.yml)
- [TestFlight配布処理](https://github.com/snarfnet/fukusou-kion/actions/workflows/typo-testflight.yml)
- [App Store Connect](https://appstoreconnect.apple.com/apps/6824906557/testflight)

配布処理では検証済みのソースを確認してから、専用の一時署名・アーカイブ・アップロード・Apple側の処理確認を行います。既存アプリの証明書は失効させません。秘密鍵はGitHub Secretsと一時ランナー内で扱い、ソースや配布ZIPには含めません。

## 検証と範囲

実行結果は`VALIDATION.txt`、仕様との対応は`REQUIREMENTS.md`に記録しています。シミュレータの成功は実機での性能保証ではありません。実機での60/30fps、発熱、連続4K動画出力、VoiceOverの読み上げは別途確認が必要です。

描画はCore Textの字形輪郭とSceneKitの押し出しを利用します。ベベルは字形の破綻を抑えるため厚さの半分までに制限します。未対応文字・絵文字・複雑すぎる輪郭は理由を表示します。

画面幅に応じて上下・左右に配置し、広い画面ではパネルの左右を入れ替えられます。特定機種の未確認の折り目角度APIには依存していません。日本語・英語UI、Dynamic Type、Reduce Motion、触覚・操作音・省電力設定を用意しています。

自動保存直前の強制終了では直近1.5秒分の編集を失う可能性があります。保存済みJSONはatomicに更新し、破損ファイルは消さずに他の作品を読み込みます。

## 権利とプライバシー

フォントは改変していないNoto Serif CJK JP Regularです。SIL Open Font License 1.1の全文をアプリ内設定と`TYPO/Resources/OFL.txt`に収録しています。環境マップ・素材表現・操作音はこのアプリ用に生成したものです。外部BGMは使っていません。

作品の文字と編集値は端末内に保存します。アクセス解析・広告・StoreKit・アプリ独自のネットワーク通信は含みません。OS標準の共有操作を行ったときだけ、選んだ共有先へ出力ファイルを渡します。

- [Noto CJK配布元](https://github.com/notofonts/noto-cjk)
- [Core Text](https://developer.apple.com/documentation/coretext)
- [SCNShape](https://developer.apple.com/documentation/scenekit/scnshape)
