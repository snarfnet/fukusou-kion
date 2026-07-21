# プラットフォーム出荷チェック

## 共通

- Unity 6.3 LTSの同じパッチ版でCIと開発機を固定
- EditModeとPlayModeテストを全件成功させる
- 30分の連続対戦で進行不能と得点不整合がない
- 60fps基準。投擲中の1% Lowを50fps以上に保つ
- 日本語と英語の全UIをコントローラーだけで操作可能にする
- セーブ破損時に`.bak`から復旧できる
- 実在する人物、流派、家紋を許諾なく使用しない

## iOS

- Mac、現行Xcode、iOS Build SupportでXcodeプロジェクトを生成
- Bundle ID、署名チーム、App Store ConnectのApp IDを一致させる
- iPhone SE相当から最新Pro Max、iPadでセーフエリアを確認
- タッチキャンセル、着信復帰、バックグラウンド復帰を確認
- 触覚を無効化できる設定を用意
- Game CenterとiCloud利用時はEntitlementsとプライバシー表記を確認
- TestFlightで外部テスト後に審査提出

## Steam

- Windows x64 IL2CPPビルドを作成
- 16:9、16:10、21:9、Steam Deck 1280×800を確認
- Steam InputでXbox、PlayStation、Switch系パッドを共通操作へ割り当てる
- Steam Cloudの保存対象をユーザー別スロットに限定
- オーバーレイ表示中は投擲入力を停止
- 実績解除はルール層の確定イベント後に行う
- 体験版と製品版でApp ID、保存領域、実績を分ける
- Steam Deckでは文字高18px相当以上、40px相当の操作領域を確保
- 横画面Canvasは1600×900基準とし、Steam Deck 1280×800で最小22px文字を約18.6px、圧縮後の最小68pxボタンを約41.3pxで表示する
- `Best Fit`による自動縮小も22pxを下限とし、長い英語文がDeck上で18px相当未満にならないよう折り返しを優先する
- 設定・結果・チュートリアルから敵選択へ戻った際は、敵1固定ではなく現在選択中の敵へゲームパッドフォーカスを復元する

Steamworksアダプターはオーバーレイの開閉コールバックから`PlatformActivityState.SetOverlayActive(bool)`を呼ぶ。開いた時点で試合と音声を停止し、閉じた後も自動投擲を避けるためプレイヤーが「試合へ戻る」を選ぶまで停止を維持する。

## ビルドメニュー

Unityの `Tools > SHINOBI ZERO` から設定、試作シーン生成、iOS、Windowsビルドを実行する。CIでは同じメソッドを `-executeMethod` で呼ぶ。

製品ビルドでは環境変数を設定する。バージョンは3区切りの数値、ビルド番号はプラットフォームをまたいで単調増加させる。

```powershell
$env:SHINOBI_ZERO_VERSION = "1.0.0"
$env:SHINOBI_ZERO_BUILD_NUMBER = "100"
```

iOSとWindowsの各出力先へ`build-manifest.json`を生成し、製品名、バージョン、ビルド番号、Unity版、UTC時刻、対象、出力、容量を記録する。ストアへアップロードしたバイナリと同じマニフェストを保管する。
