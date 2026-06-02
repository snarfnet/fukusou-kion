# Tsuchinoko Candidate Model

このモデルは、カメラ映像からツチノコらしい形を探すための試作モデルです。本物のツチノコを断定するものではありません。

アプリでは候補スコアとして表示します。通知は、強い候補が連続して見えたときだけ出します。

## ラベル

- `tsuchinoko_candidate`: 太く短い胴体、低い姿勢、胴体に近い頭部、地面に沿ったUMAらしい輪郭
- `not_tsuchinoko`: 普通のヘビ、枝、つる、ホース、ロープ、根、濡れた葉、影、帽子、服、バッグ、靴、ボトル、箱など

## データ方針

- 利用許可を確認した実写画像は `raw/positive_licensed` に入れる
- 生成画像や合成した正例は `raw/positive_synthetic` に入れる
- 誤検出を減らす負例は `raw/negative` に入れる
- 権利が不明な画像は学習に使わない
- 実地カメラの負例を増やす。誤通知を減らすにはここが一番大事

## 今回の方向

今回の更新は、帽子や洗濯物だけを避ける修正ではありません。二値分類モデルが普通の物に99%を出す問題を抑えるため、ツチノコらしい形と普通の物体を学習上で強く分けます。

追加データでは次を重視しています。

- 短く太い胴体
- 頭部と胴体の比率
- 地面に沿った低い姿勢
- 枝、つる、ホース、普通のヘビとの輪郭差
- 帽子、服、バッグ、靴、ボトル、箱など普通の物体との違い

## フォルダ

- `raw/positive_licensed`: 利用許可を確認した元画像
- `raw/positive_synthetic`: 生成した正例画像
- `raw/negative`: 誤検出を減らす負例
- `processed/train`: 学習用に整えた画像
- `processed/val`: 検証用に整えた画像
- `augmented`: 増強後の学習・検証画像
- `manifests`: 画像ソース、プロンプト、ライセンス、分割情報
- `models`: 学習済みCore MLモデルと評価結果
- `scripts`: 整理、増強、集計、学習、評価スクリプト

## 現在のデータ量

- 増強前の承認済み元画像: 266枚
- `tsuchinoko_candidate`: 133枚
- `not_tsuchinoko`: 133枚
- 今回追加した普通物体の負例: 72枚
- 今回追加した厳しめのツチノコ正例: 72枚
- 次回学習時の増強後画像: 7350枚
- 増強後 `tsuchinoko_candidate`: 3682枚
- 増強後 `not_tsuchinoko`: 3668枚

まだ試作段階の数です。実用に近づけるには、実際に設置する場所のカメラ映像、とくに負例を増やします。

## 手順

```bash
python ml/tsuchinoko/scripts/generate_shape_focus_dataset.py
python ml/tsuchinoko/scripts/generate_common_object_negatives.py
python ml/tsuchinoko/scripts/generate_strict_tsuchinoko_positives.py
python ml/tsuchinoko/scripts/prepare_dataset.py
python ml/tsuchinoko/scripts/augment_dataset.py
python ml/tsuchinoko/scripts/dataset_report.py
python ml/tsuchinoko/scripts/quality_check.py
```

`manifests/dataset.csv` の `split` 列で `train` と `val` を指定します。評価を安定させるため、検証用画像は固定します。

実地画像を取り込む場合:

```bash
python ml/tsuchinoko/scripts/import_field_data.py --label not_tsuchinoko
python ml/tsuchinoko/scripts/import_field_data.py --label not_tsuchinoko --license-status approved --confirm
```

Core MLの学習はmacOSで実行します。

```bash
swift ml/tsuchinoko/scripts/train_create_ml.swift
swift ml/tsuchinoko/scripts/evaluate_coreml.swift
```

GitHub Actionsでは `Train Tsuchinoko Core ML` を実行します。成功すると `TsuchinokoCandidate-CoreML` に次が入ります。

- `TsuchinokoCandidate.mlmodel`
- `evaluation.csv`
- `evaluation.json`
- `hard_examples`

## 最新モデル

- モデル: `models/TsuchinokoCandidate.mlmodel`
- GitHub Actions run: `26816367982`
- 評価画像: 144枚
- 評価精度: `0.7569444444444444`
- 誤検出: 15枚
- 見逃し: 20枚

次の学習では、普通物体の負例と厳しめの正例を入れた評価セットで見ます。ここで誤検出が減っているか、見逃しが増えすぎていないかを確認します。
