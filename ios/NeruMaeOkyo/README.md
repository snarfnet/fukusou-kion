# 寝る前に聞くお経

睡眠前のリラックスをサポートする、お経ASMR風のiOSアプリです。宗教色を強くせず、真っ暗な画面、低くやさしい声、木魚、鐘、低音ドローンで静かな寝落ち環境を作ります。

## 実装済み

- 3分、10分、30分、無限ループ
- AVFoundation / AVAudioPlayerによる複数音源の同時再生
- 読経、木魚、鐘、低音ドローンの音量調整
- 終了30秒前からのフェードアウト
- バックグラウンド再生
- 黒基調UI、再生中画面、残り時間、円形アニメーション
- 7人の住職選択、住職ごとの声質と再生中テキスト表示
- OpenAI TTSで読経風MP3を生成し、端末内に保存して優先再生

## OpenAI TTS

設定画面にOpenAI APIキーを入れると、`gpt-4o-mini-tts`で読経風ボイスを生成します。生成した音声はアプリのDocumentsに`openai_okyo_low.mp3`として保存され、次回の再生から`okyo_low.mp3`より優先されます。

本番配布では、開発者のAPIキーをアプリに埋め込まないでください。App Store向けには、事前に生成した音声素材を`NeruMaeOkyo/Audio/okyo_low.mp3`として同梱する形が安全です。

OpenAIのTTS音声を使う場合、アプリ内で「AI生成音声を使う場合があります。人の声ではありません。」と表示しています。

PowerShellで同梱用の読経ボイスを作る場合は、次を実行してください。

```powershell
cd "C:\Users\Windows\Documents\New project\ios\NeruMaeOkyo"
$env:OPENAI_API_KEY="sk-..."
.\scripts\generate_priest_tts.ps1
```

生成先は`NeruMaeOkyo/Audio/guide_*.mp3`です。7人分をまとめて作ります。

1人だけ作る場合:

```powershell
.\scripts\generate_priest_tts.ps1 -GuideId genkai
```

## 音源

MVP用の仮音源を同梱しています。

- `okyo_low.mp3`
- `guide_genkai.mp3`
- `guide_toma.mp3`
- `guide_myono.mp3`
- `guide_seigaku.mp3`
- `guide_sangen.mp3`
- `guide_fukusho.mp3`
- `guide_shodo.mp3`
- `mokugyo.mp3`
- `bell.mp3`
- `drone.mp3`

差し替える場合は、同じファイル名で`NeruMaeOkyo/Audio`に入れてください。

## ビルド

`NeruMaeOkyo.xcodeproj`をXcodeで開き、`NeruMaeOkyo`スキームを選んでビルドしてください。

`project.yml`も同梱しています。XcodeGenを使う場合は、このフォルダで`xcodegen generate`を実行できます。

## GitHub Actions / TestFlight

`.github/workflows/neru-mae-okyo-testflight.yml`を追加しています。GitHubにpushすると、macOSランナーでArchiveし、App Store Connectへアップロードします。

必要なGitHub Secrets:

- `ASC_KEY_ID`
- `ASC_ISSUER_ID`
- `ASC_PRIVATE_KEY` または `ASC_API_KEY_CONTENT`
- `IOS_DISTRIBUTION_P12_BASE64` または `DIST_CERT_BASE64`
- `IOS_DISTRIBUTION_P12_PASSWORD` または `DIST_CERT_PASSWORD`
- `NERU_MAE_OKYO_APP_ID`。App Store Connectでアプリを手動作成する場合に使います。

ワークフローは`com.tokyonasu.nerumaeokyo`のBundle IDとApp Store Connectアプリを確認し、なければ作成します。ビルド番号は`GITHUB_RUN_NUMBER + 100`です。
