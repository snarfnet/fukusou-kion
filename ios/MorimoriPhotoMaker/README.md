# 盛り盛りフォトメーカー iOS

WebプロトタイプをもとにしたSwiftUI版です。

## 実装済み

- 写真選択
- 生成済み盛り素材の同梱
- カテゴリ別素材一覧
- レイヤー追加
- ドラッグ移動、大きさ、回転、透明度
- 背面、前面、反転、複製、削除
- おまかせ盛り
- 共有
- `free`, `morimoriPack1`, `morimoriPack2` の課金パック区分

## GitHub Actions / TestFlight

`.github/workflows/morimori-photo-maker-testflight.yml` を手動実行すると、macOSランナーでXcodeGen、Archive、App Store Connectアップロードを行います。

必要なGitHub Secrets:

- `ASC_KEY_ID`
- `ASC_ISSUER_ID`
- `ASC_PRIVATE_KEY` または `ASC_API_KEY_CONTENT`
- `MORIMORI_PHOTO_MAKER_APP_ID`

Bundle ID:

- `com.tokyonasu.morimoriphotomaker`

WorkflowはApp Store ConnectのアプリレコードとBundle IDを確認し、ビルド番号は `GITHUB_RUN_NUMBER + 100` を使います。

## ローカルMacビルド

```bash
cd ios/MorimoriPhotoMaker
xcodegen generate
xcodebuild -project MorimoriPhotoMaker.xcodeproj -scheme MorimoriPhotoMaker -destination "generic/platform=iOS" build
```

このWindows環境ではXcodeビルドを実行できません。GitHub ActionsまたはMacで確認してください。
