# Source Candidates

学習に使う画像は、利用規約、商用利用、再配布可否を確認してから入れます。確認できない画像は学習に使いません。

## Positive Candidates

| Source | URL | Status | Note |
| --- | --- | --- | --- |
| Wikimedia Commons Category:Tsuchinoko | https://commons.wikimedia.org/wiki/Category:Tsuchinoko | check_required | ファイルごとのライセンス確認が必要 |
| イラストの里 | https://poromi-free.net/culture/legendary-creature/05-10-190818-tutinoko/ | check_required | 商用可に見えるが、AI学習利用は規約確認が必要 |
| icooon-mono | https://icooon-mono.com/15167-%E3%83%84%E3%83%81%E3%83%8E%E3%82%B3%E3%82%A2%E3%82%A4%E3%82%B3%E3%83%B32/ | check_required | アイコン素材。学習利用は規約確認が必要 |
| 素材ラボ | https://www.sozailab.jp/sozai/detail/3238/ | check_required | 会員・利用条件の確認が必要 |
| M/Y/D/S | https://myds.jp/animal/uma/tsuchinoko/sp/ | restricted | リンク条件あり。学習利用は避けるのが無難 |

## Negative Candidates

| Class | Examples |
| --- | --- |
| snake | ヘビ全般 |
| lizard | トカゲ、ヤモリ |
| branch | 地面の枝、根 |
| hose | ホース、ロープ |
| leaf_shadow | 落ち葉、影 |

## Field Data Intake

実用に近づけるには、現地カメラ映像から負例を増やします。

- 誤検知しやすい枝、根、ホース、影を優先する
- 普通のヘビやトカゲを多めに入れる
- 夜間、雨上がり、逆光、低解像度、ブレを含める
- 人物、住所、車のナンバーなど個人情報が写る素材は使わない
- 使う前に `manifests/dataset.csv` へ出典と許諾状態を記録する

## Dataset Rule

`license_status` が `approved` の画像だけを `processed` に入れます。
