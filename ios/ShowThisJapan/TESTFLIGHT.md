# TestFlightアップロード

## 必要なもの

- macOSと最新安定版Xcode
- Apple Developer ProgramのTeam ID
- App Store Connectに登録済みのBundle ID
- App Manager権限以上のApp Store Connect APIキー
- XcodeGen（`brew install xcodegen`）

## 実行

APIキーの `.p8` はリポジトリへ追加しません。macOSの安全な場所へ保存し、次の環境変数を設定します。

```bash
export SHOW_THIS_JAPAN_BUNDLE_ID="com.yourcompany.showthisjapan"
export APPLE_TEAM_ID="XXXXXXXXXX"
export ASC_KEY_ID="XXXXXXXXXX"
export ASC_ISSUER_ID="00000000-0000-0000-0000-000000000000"
export ASC_KEY_PATH="$HOME/private_keys/AuthKey_XXXXXXXXXX.p8"
./scripts/upload_testflight.sh
```

スクリプトはプロジェクト生成、Releaseアーカイブ、署名、App Store Connectへのアップロードまで実行します。Appleでの処理完了後、TestFlight画面で輸出コンプライアンス回答とテスター設定を行います。

## スクリーンショット

`output/playwright` に6.7インチ用の1290×2796画像が3枚あります。これは画面仕様から作った提出準備用モックです。App Storeの審査提出では、macOSのiOSシミュレーターまたは実機から同じ画面を撮影した画像へ差し替えてください。
