# 2026年度 中間研究報告

ISSUE-1673 の中間研究報告スライド。`slides.md`（Slidev + `slidev-theme-academic`）がスライド本体です。

## 構成

- `slides.md`: スライド本体（frontmatter で `theme: academic` を指定）
- `data/raw/`: 収集した事実データと、推定で作成した計画データ
- `data/processed/`: プロット用に集計したデータ
- `assets/source/`: Hugging Face、DagsHub、過去の発表資料から集めた画像素材
- `plots/`: Slidev で利用できる PNG / SVG
- `scripts/collect_data.py`: GitHub・Hugging Face・DagsHub の収集
- `scripts/plot.py`: プロットの再生成

## 実行

```shell
bun install
bun run check
source ~/.zshrc
bun run collect
bun run plot
bun run dev    # スライドのプレビュー
bun run build  # dist/ へのビルド
```

## データの扱い

- Hugging Face の LERF-OVS は約 3.11 GB あるため、全体を複製せず、インベントリと代表画像だけを保存します。
- DagsHub は `DAGSHUB_USER_TOKEN` または `DAGSHUB_TOKEN` を使用します。トークン自体は保存しません。
- DagsHub の画像は個別ファイルのまま保存し、比較時の選択と配置はスライド本体で行います。
- プロットは1つの論点または1つのrun種類につき1枚とし、同種の完了済みrunはシーン別に重ねて比較します。
- 図中の説明は日本語、軸名と千単位の目盛りは英語・`k`表記で生成します。
- 未完了runのプロットとrun状況図は生成しません。
- 2026-08-02 の取得時点では、24 run、96,298メトリクス履歴点、110画像（約63 MiB）です。チェックポイントは取得しません。
- running 状態の run はスナップショットです。再取得するとCSV・画像・プロットが更新されます。
- `summer_plan.csv` と `autumn_plan.csv` は、ISSUE-1673 と 2026-07-14 時点の未完了項目から作成した提案です。確定日程ではありません。
