# Tsuchinoko Candidate Model

ツチノコそのものを断定するモデルではありません。山道や草地の映像から「ツチノコらしい動体候補」を拾うための、試作用の学習セットです。

アプリ上では「ツチノコ候補」または「UMA候補」のように表示する想定です。

## ラベル

- `tsuchinoko_candidate`: 太く短い胴体、ヘビに近い頭部、地面を横切るUMA風の対象
- `not_tsuchinoko`: ヘビ、トカゲ、枝、落ち葉、ホース、ロープ、根、影など

## 方針

- ネット画像は利用規約を確認してから `raw/positive_licensed` に入れる
- 利用規約が不明な画像は学習に使わない
- ImageGenなどで作った合成画像は `raw/positive_synthetic` に入れる
- 誤検知を減らすため、実写寄りの負例を多めに集める
- まずは `tsuchinoko_candidate / not_tsuchinoko` の2クラス分類で進める

## フォルダ

- `raw/positive_licensed`: ライセンス確認済みのツチノコ素材
- `raw/positive_synthetic`: 生成画像
- `raw/negative`: 誤検知を減らすための負例
- `processed/train`: 学習用
- `processed/val`: 検証用
- `augmented`: 増強後の学習・検証画像
- `manifests`: 画像ソース、プロンプト、ライセンスメモ
- `models`: 書き出したCore MLモデル
- `scripts`: 整理、増強、集計、Core ML変換

## 注意

本物のツチノコ画像が存在しないため、現実の映像では太いヘビ、枝、ホースなどを候補として拾う可能性があります。実用に近づけるには、現地のトレイルカメラ映像から負例を増やし、正例の画風、角度、距離も広げます。

## 現在のデータ量

- 承認済み元画像: 17枚
- 増強後画像: 3312枚
- `tsuchinoko_candidate`: 1536枚
- `not_tsuchinoko`: 1776枚

この数はプロトタイプ用です。実用に近づけるには、実地映像の負例を中心に増やします。

## 手順

```bash
python ml/tsuchinoko/scripts/prepare_dataset.py
python ml/tsuchinoko/scripts/augment_dataset.py
python ml/tsuchinoko/scripts/dataset_report.py
python ml/tsuchinoko/scripts/quality_check.py
```

実地画像を取り込む場合は、まず `field_data/positive_review` または `field_data/negative_review` に置き、ドライランで確認します。

```bash
python ml/tsuchinoko/scripts/import_field_data.py --label not_tsuchinoko
python ml/tsuchinoko/scripts/import_field_data.py --label not_tsuchinoko --license-status approved --confirm
```

Core MLモデル作成はmacOSで行います。

```bash
swift ml/tsuchinoko/scripts/train_create_ml.swift
swift ml/tsuchinoko/scripts/evaluate_coreml.swift
```

GitHub Actionsから作る場合は `Train Tsuchinoko Core ML` を実行します。成功すると `TsuchinokoCandidate-CoreML` アーティファクトに `.mlmodel`、`evaluation.csv`、`evaluation.json` が入ります。

`evaluation.csv` は画像ごとの正解ラベル、予測ラベル、信頼度、正誤を出します。外した画像を見れば、次に集めるべき負例や正例を決めやすくなります。

## 最新モデル

- モデル: `models/TsuchinokoCandidate.mlmodel`
- GitHub Actions run: `26754037593`
- Artifact ID: `7331562935`
- 検証エラー: `0.09375`
- 検証精度の目安: `0.90625`

検証データも合成寄りなので、この数字は動作確認レベルです。実用に進めるには、現地映像の負例と、実写に近い候補画像を足して再学習します。
