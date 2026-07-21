# TestFlight CI

GitHub Actionsの `SHINOBI ZERO TestFlight Upload` が、Unity iOSプロジェクト生成、署名、Archive、IPA出力、TestFlightアップロード、処理完了待機を順番に実行する。

## 必要なGitHub Secrets

- `UNITY_LICENSE`：GameCIで利用するUnityライセンスファイルの全文
- `ASC_PRIVATE_KEY`：App Store Connect APIキー（p8）の全文
- `ASC_KEY_ID`
- `ASC_ISSUER_ID`
- `IOS_DISTRIBUTION_P12_BASE64`
- `IOS_DISTRIBUTION_P12_PASSWORD`

Apple関連の5項目はリポジトリへ登録済み。現在不足しているのは `UNITY_LICENSE`。

## 固定値

- Bundle ID：`com.shinobizero.game`
- Team ID：`83VGKGSQUH`
- Unity：`6000.3.0f1`
- 最低iOS：15.0
- 初期バージョン：0.1.0

WorkflowはBundle IDとApp Store Connectのアプリが未登録なら自動作成する。アプリ名がApple側ですでに使われている場合は、その工程で停止する。

## 実行

専用ブランチへのpushで自動実行する。`UNITY_LICENSE`登録後はGitHub Actionsから手動再実行でき、`version`へ公開バージョンを指定できる。

認証情報、証明書、プロビジョニングプロファイルは成果物へ含めず、GitHub Secretsと一時Keychainだけで扱う。
