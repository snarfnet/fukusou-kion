# App Store提出チェックリスト

## 開発者情報が必要

- [ ] `PRODUCT_BUNDLE_IDENTIFIER`を所有するBundle IDへ変更
- [ ] Signing TeamをXcodeで設定
- [ ] App Store Connectに新規アプリを作成
- [ ] 販売者名または著作権表記を入力
- [ ] 公開サポートURLを設定
- [ ] 公開プライバシーポリシーURLを設定
- [ ] プライバシーポリシーのお問い合わせ先を実在する窓口へ変更

## ビルド

- [ ] macOS CIまたはMacのXcodeで全XCTestを通す
- [ ] iPhone SE、6.9インチiPhone、13インチiPadで画面を確認
- [ ] VoiceOverと最大文字サイズで主要導線を確認
- [ ] Release構成でArchive
- [ ] OrganizerのValidate Appを通す
- [ ] `PrivacyInfo.xcprivacy`がArchiveへ含まれることを確認
- [ ] 1024×1024アイコンにアルファチャンネルがないことを確認

## App Store Connect

- [ ] `METADATA_JA.md`の説明、キーワード、プロモーション文を入力
- [ ] iPhone 6.9インチのスクリーンショットを1〜10枚登録
- [ ] iPad 13インチのスクリーンショットを1〜10枚登録
- [ ] App Privacyを「データ収集なし」「追跡なし」で回答
- [ ] 年齢区分質問票を`REVIEW_NOTES_JA.md`に沿って回答
- [ ] GamblingはNo、Simulated GamblingはNoneであることを機能と再確認
- [ ] 暗号化質問で非免除暗号なしを回答
- [ ] 審査メモを登録

## 最終確認

- [ ] 新規インストールで初回チュートリアルが開く
- [ ] 五校を順番に解放できる
- [ ] 中断対局を再開できる
- [ ] 最終校勝利後にエンディングへ進む
- [ ] 「記録を消して最初から」が動作する
- [ ] 音、振動、打牌確認の設定が保存される
- [ ] 広告、課金、ログイン、外部通信が存在しない

