# SHINOBI ZERO — Unity製品版

iOS版を先に完成させ、後からSteamへ展開できるようゲームルールを分離したUnity 6.3 LTSプロジェクトです。

## 現在の実装

- 301・501、三投交代、バースト、ダブルアウト、1 LEG・BEST OF 3
- 初戦はプレイヤー先攻、完了した再戦ごとに先攻を交代し、中断では順番を維持
- ダーツ盤の座標から得点を決める純粋C#ルール層
- 170mm外周を基準にしたブル、トリプル、ダブルの実寸比と20セクター盤面
- 残り点数に応じてダブルやトリプルを選ぶ敵AI
- 2〜170点の全上がり目と公式ボギーナンバーを網羅検証するチェックアウト案内
- 技量、安定性、プレッシャー耐性、狙い癖が異なる5人の敵
- 堅実型、連投型、強襲型、詰将棋型、無形型に分かれる5種類の戦術AI
- 実際の盤面得点を使う決定論的シミュレーションで検証した5段階の難易度曲線
- 構え、引き、リリース、残心を持ち、5人で速度と振り幅が異なる忍者投擲モーション
- ブル、トリプル、BUST、LEG、勝敗に応じた敵忍者の頷き、苛立ち、勝利姿勢、敗北姿勢
- プレイヤーは手前の一人称位置、敵は画面内忍者の手首から投げる発射元分離
- プレイヤー入力の強さと横回転に連動する一人称の構え・引き・手首返し・リリース・残心
- 肩書き、戦術説明、装束色、金具色が切り替わる5人の対戦者
- タッチとマウスを共通化した投擲ジェスチャー
- ゲームパッド左スティック／WASD・矢印照準と、右トリガー／F長押し投擲
- キーボード／ゲームパッド接続時だけ有効になる全メニューの既定フォーカスと選択復帰
- 設定から即時切替できる日本語／英語UI、敵紹介、試合案内、結果、チュートリアル、実績名
- SIL Open Font License 1.1のNoto Sans JPを同梱し、iOS・Windows・macOS・Linuxで日本語表示を統一
- 指を離した盤面位置で狙い、スワイプ速度と横流れで精度・威力・回転が変化する照準
- プレイヤーの押下中だけ表示され、盤面外入力も実着弾範囲へ追従する照準マーク
- 下向き、短い、遅い、長押しを判別して投げ方を伝える入力フィードバック
- Rigidbodyによる手裏剣の飛行、回転、盤面への固定
- 重力を逆算する低弾道ソルバーと高速投擲用の連続衝突判定
- 立体的な四方手裏剣と、ターン交代時の安全な刺さり物管理
- 投擲速度に連動する風切り音、命中素材別の音、短いカメラ反応
- シングル、ダブル、トリプル、ブル、BUST、勝敗を判別する火花・音・触覚・カメラズーム演出
- iPhone触覚と同じ4段階を左右モーターへ変換するSteam／Steam Deckゲームパッド振動
- 決定論的に生成する寺の雨風ループ音と、最大520粒の低負荷な雨表現
- 端末メモリと継続フレーム時間から雨粒・影・AAを3段階で自動調整し、安定後だけゆっくり品質復帰
- iOS、Steam、ローカル保存を分けるサービス境界
- iPhone縦画面HUD、セーフエリア、ネイティブ触覚
- iPhone縦画面とWindows／Steam Deck横画面を自動判別するレスポンシブHUD
- 保存時の一時ファイルとバックアップ
- 最新戦績が破損した場合の前世代バックアップ自動復旧
- ローカル、前世代バックアップ、クラウドからリビジョン・試合数・更新時刻で最新キャリアを選び、旧形式と異常値を自動修復
- 勝敗、命中率、最高得点、最高チェックアウト、敵別勝利数の端末保存
- 全敵を自由選択できるまま、勝利数と撃破人数で見習い・下忍・中忍・上忍・影へ進むキャリア階級
- 試合前後の階級を比較し、実際の昇格時だけ日英で表示する専用通知
- iOSローカルと将来のSteamで共通利用する6個の実績IDと9個の統計キー
- 新しい実績だけを一度表示するゲーム内通知
- 試合ごとの3投平均、命中率、最高ターン、最高チェックアウト
- 両者の直近3投をT20・D16・MISS形式で示すターン内訳、合計、BUST表示
- 初回3画面の遊び方ガイドと、選択画面からの再表示
- 効果音、触覚、カメラ反応のアクセシビリティ設定
- 手動ポーズ、着信、バックグラウンド移行時の安全な試合停止と敵AI再開
- フォーカス・OS中断・試合ポーズを統合し、復帰順序で環境音が漏れない音声ライフサイクル
- ポーズ画面から投擲・敵思考・物理を破棄して戦績非加算で対戦相手選択へ復帰
- EditModeテスト266件（うち5件は生成シーン受け入れテスト）

## 開き方

1. Unity HubからUnity 6.3 LTSを導入する
2. iOS Build Support、Windows Build Support（IL2CPP）を追加する
3. Unity Hubでこのフォルダをプロジェクトとして開く
4. Package Managerの復元が終わるまで待つ
5. `Window > General > Test Runner` からEditModeテストを実行する
6. `Tools > SHINOBI ZERO > Create 3D Prototype Scene` を実行する
7. 生成された `Assets/ShinobiZero/Generated/Prototype.unity` を再生する

Unityを開く前の構造チェックは次のコマンドで実行する。

```powershell
node Tools/validate-project.js
PowerShell -ExecutionPolicy Bypass -File Tools/test-core.ps1
python Tools/validate-ios-icons.py
python Tools/validate-privacy-manifest.py
```

Unity導入後は、生成シーンを含むEditModeテストをバッチ実行できる。

```powershell
PowerShell -ExecutionPolicy Bypass -File Tools/run-unity-tests.ps1 `
  -UnityPath "C:\Program Files\Unity\Hub\Editor\6000.3.xf1\Editor\Unity.exe"
```

結果は `TestResults/editmode-results.xml`、詳細ログは `TestResults/editmode.log` に出力される。

## 入力

画面下から上へドラッグする。タッチとマウスの両方をInput Systemで読み取る。上方向の距離を力、左右のずれを照準と回転へ変換する。

## フォルダ

```text
Assets/ShinobiZero/Core       Unity非依存のルールとAI
Assets/ShinobiZero/Runtime    入力、物理、プラットフォーム境界
Assets/ShinobiZero/Editor     製品シーンとiOS・Windows・macOS・Linuxビルド生成
Assets/ShinobiZero/Tests      EditMode自動テスト
```

## 未実装

- Unity Editorでの実コンパイル、生成シーン受け入れテスト、iPhone実機確認
- 制作済みの高精細3Dモデル、モーションキャプチャ、収録音源への最終差し替え
- Steamworks、Game Center、クラウドセーブの実アダプター
- 英語UIとゲームパッド投擲の実機最終検証
- 実機パフォーマンス計測とストアビルド

iOS優先の残作業と実機確認項目は `Docs/IOS_FIRST_PLAN.md` にまとめています。

ブラウザ試作のルールと見た目は `../shinobi-zero` にあります。
