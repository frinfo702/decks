#import "@preview/touying:0.6.1": *
#import themes.metropolis: *
#import "@preview/numbly:0.1.0": numbly
#import "@preview/presio:0.1.0": media
#import "@preview/cheq:0.2.2": checklist

#set heading(numbering: numbly("{1}.", default: "1.1"))
#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  config-info(
    title: [個別ゼミ],
    subtitle: [Spatial Relation Search in 3D Scenes],
    author: [Kenichiro Goto],
    date: "2026-07-14",
  ),
)
#show raw.where(block: true): set text(size: 11pt, font: "Geist Mono")
#show figure.where(kind: raw): it => {
  show figure.caption: set text(size: 10pt, fill: luma(120))
  it
}
#show figure.where(kind: table): it => {
  show figure.caption: set text(size: 12pt, fill: luma(120))
  it
}
#set text(font: "Hiragino Kaku Gothic ProN", size: 14pt, lang: "ja")
#show: checklist

// title
#show link: set text(fill: blue)
#set page(background: image("images/owl_and_fox.png"))
#title-slide()[]
#set page(background: image("images/presentation_background.png"))


---

= 実験管理の整備

---

== 今週の進捗（1）

画像を毎回手元で見比べるのが大変だったので、LangSplat 学習に DagsHub / MLflow トラッキングを追加した

#link(
  "https://github.com/frinfo702/3dgs-relationship-recognition/pull/4",
)[github.com/frinfo702/3dgs-relationship-recognition/pull/4]

#v(0.4em)

- 複数 run（sofa / lerf_ovs など）を同じプロジェクト上で比較したい
- 実験ごとのパラメータ・loss・評価指標・画像・最終 checkpoint を一箇所に残したい
- DagsHub 上の MLflow にログを送る
- まだ使えてない
- あとデータセットをhfに移したりした


---

= 精度問題の切り分け

---

== 前回までの状況

#text(weight: "semibold")[見た目はそれっぽいのに、セグメンテーションがうまくいかない]

#columns(2)[
  #figure(
    image("images/sofa_original.gif", height: 45%),
    caption: "元シーン",
  )
  #colbreak()
  #figure(
    image("images/sofa_feat.gif", height: 45%),
    caption: "自分の学習結果の feature map",
  )
]

Relevancy Score

$
  "rel"^l(v; q) = min_i (exp(bold(phi)_"img"^l(v) dot bold(phi)_"qry")) / (exp(bold(phi)_"img"^l(v) dot bold(phi)_"qry") + exp(bold(phi)_"img"^l(v) dot bold(phi)_"canon"^i))
$

where $v$: pixel, $q$: text query, $bold(phi)$: CLIP embedding
（$bold(phi)_"img"^l(v)$: 画素 $v$ の level-$l$ 画像特徴, $bold(phi)_"qry"$: query のテキスト特徴, $bold(phi)_"canon"^i$: canonical phrase のテキスト特徴）.

---

レベル選択 → 予測位置

$
  l^* = op("argmax")_(l in {s, p, w}) max_v "smooth"("rel"^l(v; q)),
  quad
  hat(v) = op("argmax")_v "smooth"("rel"^(l^*)(v; q))
$

- feature map は出ていたが、埋め込まれた 3D 言語特徴が CLIP 空間とずれていた
  - GTと比較して、各類似度の数字をみるとまるで違うことが確認できた

#figure(
  image("images/relevancy_threshold_derivation.jpg", height: 70%),
  caption: [relevancy の変形と閾値 $0.5$ の意味],
)

- つまり学習そのものがうまくいっていなかった
- 「閾値が悪いのでは？」という議論について
  - 元の実装では$"relevancy" < 0.5$ は0にする必要があったが見落としていた.ここで挙動にも差が出ていた




---

== 公開チェックポイントで再評価

公開checkpoint を使ってデモを回したらうまくいった



#table(
  columns: (auto, 1fr),
  stroke: 0.5pt + luma(180),
  inset: 8pt,
  fill: (col, row) => if row == 0 { luma(240) } else { white },
  [*要素*], [*意味*],
  [黒の点線枠], [そのテキストプロンプトに対する GT。LERF の annotation JSON から取得し描画],
  [赤い点], [予測位置。平滑化した CLIP relevancy map の argmax],
  [カラフルな背景], [relevancy heatmap。relevancy が低い領域（$< 0.5$）は RGB を暗く表示],
)


正解の定義

- 赤い点が、そのプロンプトの GT bbox のいずれかの内側に入っていれば hitと判定する

---

== 公開 ckptでの例

#grid(
  columns: 3,
  gutter: 0.6em,
  figure(
    image("images/apple.png", width: 100%),
    caption: [query: apple],
  ),
  figure(
    image("images/coffee.png", width: 100%),
    caption: [query: coffee],
  ),
  figure(
    image("images/bag of cookies.png", width: 100%),
    caption: [query: bag of cookies],
  ),
)

赤点が GT 枠内に入り、heatmap も対象に集中している


---

== 失敗例も混在する

#figure(
  image("images/bear nose.png", height: 55%),
  caption: [query: bear nose — heatmap はクマ全体、赤点は胴体側にずれ GT 枠外],
)

論文デモと同じ評価でも、細かい部位クエリなどでは外れるケースがある


---

=== teatime 評価結果（mask thresh = 0.4）

#table(
  columns: (1.5fr, 1fr, 1fr),
  stroke: 0.5pt + luma(180),
  inset: 6pt,
  fill: (col, row) => if row == 0 { luma(240) } else { white },
  [*設定*], [*mIoU*], [*Loc. Acc.*],
  [`teatime`], [0.6503], [0.8814],
)

- 論文 Table1/2 の teatime（LangSplat）とほぼ一致
#figure(
  image("images/langsplat_paper_tables.png", height: 60%),
  caption: [LangSplat 論文の Localization / IoU 比較],
)

---

== 予測パイプライン

+ レベルごとの relevancy map を構築
+ $30 times 30$ の平均フィルタで平滑化
+ ピークが最大の SAM / feature レベルを選択 // todo: featureレベルの解説を追加
+ そのピーク位置を赤い点として描画

#v(0.5em)

公開 ckpt では localization が通るので学習の不備 がこれまで上手くいかなかった原因だった可能性が高い



---

= 位置関係クエリの試行

---

== 位置関係を含むクエリ

オブジェクト単体ではなく、位置関係を含んだクエリ を独自に試したが*うまくいかなかった*

#grid(
  columns: 2,
  gutter: 0.8em,
  figure(
    image("images/coffee next to the apple.png", width: 95%),
    caption: [query: coffee next to the apple],
  ),
  figure(
    image("images/glass next to the apple.png", width: 95%),
    caption: [query: glass next to the apple],
  ),
)

- 🚨 bouding boxはGTのもの。データのアノテーションである `category` の結果のみを書き換えただけなので、boxは変更されていない。boxは無視してください。
- どちらもりんご🍎に赤点がついてしまっている
- 現行の relevancy は 単語・物体単位の類似度 で、"next to" のような関係語を構造的に扱えない

== 位置関係を含むクエリでのメトリクス

teatime 評価結果（mask thresh = 0.4）

- 自分で`annotation`を書き換えたのはさっきの2ケースのみだが、評価対象の数自体が少ないので当然だがわかりやすく悪化している

#table(
  columns: (1.6fr, 1fr, 1fr),
  stroke: 0.5pt + luma(180),
  inset: 8pt,
  fill: (col, row) => if row == 0 { luma(240) } else { white },
  [*設定*], [*mIoU (chosen)*], [*Localization Acc.*],
  [`eval_result/teatime`], [0.6503], [0.8814],
  [`eval_result/teatime_experiment`], [0.5733], [0.7458],
)

---

== 示唆

=== 現状の限界
- 公開 ckpt で、単体オブジェクトの localization は概ね動く
- 位置関係を含む自然言語クエリは、そのままでは解けない


=== 次にやること
- クエリを「対象物体 + 関係 + 参照物体」にパースする機構
- 各物体を個別に localization したうえで、関係を検証する
  - rel3d
- まずは 2 オブジェクト・単純な空間関係から


---

= まとめ

---

== 進捗

- [x] OV-Seg 追試・SAM3 置換評価完了
- [x] 医療・衛星ドメイン調査
- [x] MedDINOv3, SkySense読む
- [x] LangSplat 読む（ざっくり）
- [x] 「3D シーン内の位置関係を含む情報検索」の検討
- [x] LangSplatを動かす
  - 自前学習の精度は不十分（CLIP 空間とのずれ）
- [x] LangSplatのlintエラー修正
- [x] DagsHub / MLflow による実験トラッキング追加（PR \#4）
- [x] 公開チェックポイントでの評価・デモ
  - 単体オブジェクト localization は成功
  - 位置関係クエリはそのままでは失敗
- [ ] Rel3Dを動かす
- [ ] 位置関係を含んだクエリをパースする機構を追加
  - まずは2つのオブジェクトから
- [ ] 自前学習の再現修正（公開 ckpt との差分切り分け）
- [ ] LERFを読む
- [ ] データセットの模索、検討
- [ ] 位置関係をLangSplatに認識させるor外部にモデル追加
