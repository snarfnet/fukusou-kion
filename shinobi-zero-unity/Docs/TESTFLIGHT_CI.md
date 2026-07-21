# TestFlight CI

GitHub Actionsの `SHINOBI ZERO TestFlight Upload` が、Unity iOSプロジェクト生成、署名、Archive、IPA出力、TestFlightアップロード、処理完了待機を順番に実行する。

## 必要なGitHub Secrets

- `UNITY_EMAIL`：Unityアカウントのメールアドレス
- `UNITY_PASSWORD`：Unityアカウントのパスワード
- `UNITY_LICENSE`：Personal利用時のUnityライセンスファイル全文
- `UNITY_SERIAL`：Pro利用時のシリアル。Personalでは不要
- `ASC_PRIVATE_KEY`：App Store Connect APIキー（p8）の全文
- `ASC_KEY_ID`
- `ASC_ISSUER_ID`
- `IOS_DISTRIBUTION_P12_BASE64`
- `IOS_DISTRIBUTION_P12_PASSWORD`

Apple関連の5項目はリポジトリへ登録済み。UnityはPersonalなら`UNITY_EMAIL`、`UNITY_PASSWORD`、`UNITY_LICENSE`、Proなら`UNITY_EMAIL`、`UNITY_PASSWORD`、`UNITY_SERIAL`を登録する。

## 固定値

- Bundle ID：`com.shinobizero.game`
- Team ID：`83VGKGSQUH`
- Unity：`6000.3.0f1`
- 最低iOS：15.0
- 初期バージョン：0.1.0

WorkflowはBundle IDとApp Store Connectのアプリが未登録なら自動作成する。アプリ名がApple側ですでに使われている場合は、その工程で停止する。

## 実行

専用ブランチへのpushで自動実行する。Unity認証情報の登録後はGitHub Actionsから手動再実行でき、`version`へ公開バージョンを指定できる。

認証情報、証明書、プロビジョニングプロファイルは成果物へ含めず、GitHub Secretsと一時Keychainだけで扱う。
