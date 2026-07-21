# App Store Connect プライバシー回答案

## 現在のオフライン版

- 「このAppからデータを収集しますか」：いいえ
- トラッキング：なし
- 広告：なし
- アカウント：なし
- 位置情報、連絡先、写真、マイク、カメラ：使用しない
- プライバシーポリシーURL：公開前に `PRIVACY_POLICY_JA.md` をHTTPSで公開して設定

投擲調整、設定、戦績は端末内だけで処理するため、Appleの説明では「収集」に当たらない。ただし、ビルドへ新しいSDKやオンライン機能を追加するたびに再監査する。

## Privacy Manifest

- `NSPrivacyTracking`：false
- `NSPrivacyCollectedDataTypes`：空
- UserDefaults：`CA92.1`。アプリ自身だけが読める投擲調整と設定を保存
- File Timestamp：`C617.1`。アプリコンテナ内のセーブファイル有無とバックアップを扱う

## 提出前の確認

1. Xcode OrganizerでPrivacy Reportを生成
2. Unityと全プラグインのPrivacy Manifestを確認
3. App Store Connectの回答と実ビルドを一致させる
4. 公開済みプライバシーポリシーURLを登録
5. Game Centerやクラウド保存を追加した場合は「ゲームプレイコンテンツ」などの申告を再判定
