# Tsuchinoko Candidate Model

このモデルは、カメラ映像の中から「ツチノコらしい候補」を見つけるための試作モデルです。
本物のツチノコを断定するものではありません。アプリでは候補スコアとして扱い、強い候補が連続して見えたときだけ通知します。

## ラベル

- `tsuchinoko_candidate`: 短く太い胴体、低い姿勢、頭と胴体のバランス、地面に沿った輪郭を持つ候補
- `not_tsuchinoko`: 普通の蛇、枝、つる、ホース、ロープ、根、濡れた葉、影、帽子、布、バッグ、靴、ボトル、箱など

## 今回の方針

普通の物でも99%が出る問題を下げるため、二値分類モデルの学習データを強めました。

- 帽子、布、バッグ、靴、ボトル、箱などの普通物体を負例に追加
- 短く太い胴体、頭と胴体の比率、低い姿勢を強めた正例を追加
- 検証セットにも普通物体を入れ、誤検出が残っていないか確認

洗濯物や帽子だけを個別に避ける修正ではなく、ツチノコらしい形と普通の物体の違いを学習側で強める方針です。

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

## 最新モデル

- モデル: `models/TsuchinokoCandidate.mlmodel`
- GitHub Actions run: `26819506050`
- 評価画像: 720枚
- 正解: 693枚
- 評価精度: `0.9625`
- 誤検出: 7枚
- 見逃し: 20枚
- 追加した普通物体の誤検出: 0枚

残った誤検出は、枝、つる、濡れた道の普通の蛇など、ツチノコ候補に形が近いものです。帽子、布、バッグ、靴、ボトル、箱は今回の検証では誤検出していません。

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

`manifests/dataset.csv` の `split` 列で `train` と `val` を固定しています。評価を安定させるため、検証用画像は固定します。

実地画像を取り込む場合:

```bash
python ml/tsuchinoko/scripts/import_field_data.py --label not_tsuchinoko
python ml/tsuchinoko/scripts/import_field_data.py --label not_tsuchinoko --license-status approved --confirm
```

Core ML の学習は macOS で実行します。

```bash
swift ml/tsuchinoko/scripts/train_create_ml.swift
swift ml/tsuchinoko/scripts/evaluate_coreml.swift
```

GitHub Actions では `Train Tsuchinoko Core ML` を実行します。成功すると `TsuchinokoCandidate-CoreML` に次が入ります。

- `TsuchinokoCandidate.mlmodel`
- `evaluation.csv`
- `evaluation.json`
- `hard_examples`
