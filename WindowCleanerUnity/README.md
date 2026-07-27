# Glass Craft — iOS Unity prototype

窓清掃の手順を学びながら、仕上がりを競うタッチ操作ゲームの最小試作です。

## 含まれるもの

- 汚れ確認 → 予備洗浄 → 洗剤 → スクイジー → 端部乾拭き
- 汚れ、水分、洗剤量、工程、時間による採点
- 基準未満なら再清掃
- マウスとiPhone/iPadのタッチ操作
- iOS 15以降、横画面向け設定

## 起動

1. Unity Hubでこのフォルダーを開きます。
2. Unity 6（6000.0系）で空のSceneを作るか、既存の空Sceneを開きます。
3. Playを押します。ゲーム画面は実行時に自動生成されます。
4. iOS実機用は `File > Build Profiles > iOS` からXcodeプロジェクトを書き出します。

Bundle Identifierは `com.tokyonasu.glasscraft` です。

## GitHub Actions / TestFlight

`.github/workflows/glass-craft-testflight.yml` が次の処理を行います。

1. App Store ConnectへBundle IDとアプリを登録
2. UnityでiOS用Xcodeプロジェクトを生成
3. GitHubのMac Runnerで署名・Archive
4. TestFlightへアップロード
5. Apple側の処理完了まで確認

Apple署名はリポジトリの共通Secretsを使います。Unityビルドには
`UNITY_LICENSE`、または`UNITY_SERIAL`・`UNITY_EMAIL`・`UNITY_PASSWORD`が必要です。

## 次の実装候補

- RenderTextureを使った連続的な汚れマスク
- 3Dの室内、店舗、高層ビルステージ
- 水滴シェーダーとスクイジーのゴム変形
- ジャイロで光を動かす仕上がり検査
- Game Centerランキング、振動、効果音
