# Steam販売準備

## 対応ビルド

UnityメニューとCIの両方からWindows x64、macOS、Linux x64を生成する。Steam DeckはLinux版を第一候補とし、Proton経由のWindows版も実機で比較する。

成果物には`build-manifest.json`を同梱する。バージョン、ビルド番号、Unity版、生成日時をDepotへ登録したバイナリと対応づける。

## Steamworksを入れる前の境界

ゲームルールはSteamworks SDKを参照しない。`IPlatformServices`の実装だけを差し替え、次を接続する。

- 実績: `SZ_`で始まる固定ID
- 統計: `PlatformProgressSnapshot`の固定ID
- Cloud: UTF-8の`career-cloud.json`
- Overlay: `PlatformActivityState.SetOverlayActive(bool)`

Steam App IDが発行されるまではSDKや仮のApp IDをリポジトリへ入れない。Auto Cloudを使う場合は、各OSのUnity永続データ領域にある`Cloud/career-cloud.json`と`.bak`だけを同期対象にする。

## 出荷ゲート

- Windows、macOS、Linuxで同じセーブを往復する
- Steam Deck 1280×800、16:9、21:9でUIが欠けない
- Xbox、PlayStation、Switch系パッドをSteam Inputで確認する
- Overlay表示中は入力、敵AI、音声を停止する
- オフライン起動後の実績と統計を再接続時に送信する
- Depotの実行ファイルと起動オプションをOS別に確認する
- ストア画像は実ゲーム画面とコンセプト画像を区別する

