# Tsuchinoko Candidate Model

ツチノコを断定するモデルではなく、山道や草地の映像から「ツチノコらしき動体」を候補として拾うための学習セットです。

## ラベル

- `tsuchinoko_candidate`: 太く短い胴体、ヘビに近い頭部、地面を横切るUMA風の対象
- `not_tsuchinoko`: ヘビ、トカゲ、枝、落ち葉、ホース、ロープ、猫のしっぽ、影など

## 方針

- ネット画像は利用規約を確認してから `raw/positive_licensed` に入れる
- 規約未確認の画像は学習に使わない
- ImageGenなどで作った合成画像は `raw/positive_synthetic` に入れる
- 誤検出候補はできるだけ実写寄りに集める
- 最終的には `tsuchinoko_candidate / not_tsuchinoko` の2クラス分類から始める

## フォルダ

- `raw/positive_licensed`: ライセンス確認済みのツチノコ素材
- `raw/positive_synthetic`: 生成画像
- `raw/negative`: 誤検出候補
- `processed/train`: 学習用
- `processed/val`: 検証用
- `manifests`: 画像ソース、プロンプト、ライセンスメモ
- `scripts`: 整理・学習・Core ML変換の補助

## 注意

本物のツチノコ画像が存在しないため、現実映像では太いヘビ、枝、ホースなどを候補として拾う可能性があります。アプリ上の表現は「ツチノコ候補」「UMA候補」が安全です。

## 現在のデータ量

- 承認済み元画像: 6枚
- 増強後画像: 248枚
- `tsuchinoko_candidate`: 124枚
- `not_tsuchinoko`: 124枚

この数はプロトタイプ用です。実用に寄せるには、実地のトレイルカメラ映像から負例を増やし、正例は画風・角度・距離が偏らないように追加します。

## 手順

```bash
python ml/tsuchinoko/scripts/prepare_dataset.py
python ml/tsuchinoko/scripts/augment_dataset.py
python ml/tsuchinoko/scripts/dataset_report.py
```

Core MLモデル作成はmacOSで行います。

```bash
swift ml/tsuchinoko/scripts/train_create_ml.swift
```

GitHub Actionsから作る場合は `Train Tsuchinoko Core ML` を手動実行します。成功すると `TsuchinokoCandidate-CoreML` アーティファクトに `.mlmodel` が出ます。

## 最新モデル

- モデル: `models/TsuchinokoCandidate.mlmodel`
- GitHub Actions run: `26748637368`
- 検証エラー: `0.375`
- 検証精度の目安: `0.625`

検証データが24枚と少ないため、これは動作確認レベルです。実用には負例を中心に増やします。
