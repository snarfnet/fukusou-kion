# Field Data Intake

ここは実地映像から切り出した候補画像を置くための受け皿です。

このフォルダへ直接入れた画像は、まだ学習には使いません。内容、許諾、個人情報を確認してから `raw` と `manifests/dataset.csv` に移します。

## 入れる場所

- `positive_review/`: ツチノコ候補として人間が確認したい画像
- `negative_review/`: 誤検知を減らすための負例候補
- `discarded/`: 個人情報や権利面で使わない画像

## 推奨する集め方

- 固定カメラやスマホで山道、草地、畑の端を撮る
- 1秒ごと、または動体検知の瞬間で静止画を書き出す
- ヘビ、枝、根、ホース、影、落ち葉を多めに残す
- 迷った画像ほど負例候補として残す

## 学習に入れる前の確認

- 人の顔、住所、車のナンバーが写っていない
- 撮影者または提供者の許可がある
- ラベルが `tsuchinoko_candidate` または `not_tsuchinoko` のどちらかに決まっている
- `manifests/dataset.csv` に出典、許諾状態、メモを記録している

## 取り込み手順

まずはドライランで確認します。

```bash
python ml/tsuchinoko/scripts/import_field_data.py --label not_tsuchinoko
```

問題なければ `--confirm` を付けます。すぐ学習に使う場合だけ `--license-status approved` を付けます。

```bash
python ml/tsuchinoko/scripts/import_field_data.py --label not_tsuchinoko --license-status approved --confirm
```

取り込み後は、必ずデータセットを作り直して品質チェックを通します。

```bash
python ml/tsuchinoko/scripts/prepare_dataset.py
python ml/tsuchinoko/scripts/augment_dataset.py
python ml/tsuchinoko/scripts/quality_check.py
```
