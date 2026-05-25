
#import "@preview/touying:0.6.1": *
#import themes.metropolis: *
#import "@preview/numbly:0.1.0": numbly

#set heading(numbering: numbly("{1}.", default: "1.1"))
#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  config-info(
    title: [個別ゼミ],
    subtitle: [OV-Seg 進捗 \ #link("https://github.com/frinfo702/ov-seg/pull/1")],
    author: [Kenichiro Goto],
    date: "2026-05-19",
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
#set text(font: "Hiragino Kaku Gothic ProN", size: 14pt, lang: "en")

// title
#show link: set text(fill: blue)
#set page(background: image("images/blue_whale.png"))
#title-slide()[]
#set page(background: image("images/presentation_background.png"))


= MaskFormer をSAM3に置き換える


---

== MaskFormer の限界

#columns(2, gutter: 2em)[
  - マスク形状精度が不十分
    - "耳"でクエリしても"人"全体のマスクしか得られない
    - クエリによらずマスク形状が変化しない
  - 学習済み MaskFormer を freeze して使用 → マスク品質は MaskFormer の学習に依存

  #colbreak()
  #figure(
    image("images/ov-seg-result-examples.png"),
    caption: "OV-Seg のセグメンテーション結果",
  )
]

---

== 改善案: MaskFormer $arrow$ SAM3

SAM3 (Meta AI, 2025):
- Promptable Concept Segmentation 用モデル
- テキストプロンプトで物体を検出・セグメンテーション
- 高品質マスクプロポーザルを生成

課題:
- MaskFormer: マスク + 埋め込みベクトルを生成
- SAM3: マスク*のみ*生成（埋め込みベクトルなし）
  - SAM3は埋め込みベクトルも生成することもできるが今回はしない
- OV-Seg の fusion と整合しない
  - $s = lambda s_"mask" + (1-lambda) s_"sam3"$ となるが、この計算はできない
  - $s_"mask"$, $s_"sam3"$ の次元が違う

---

== 解決策: $lambda = 0$

OV-Seg の最終スコアは $s = lambda s_"mask" + (1-lambda) s_"clip"$

- $lambda = 0$ にすれば CLIP 単独で分類 → SAM3 のマスクを直接 CLIP で分類可能
- fusion 不要、アーキテクチャがシンプルに

*ovsam3 :*

$"Input" arrow "SAM3 (200 queries)" arrow "CLIP ViT-L/14 (各マスク分類)" arrow "Segmentation"$

- SAM3 (encoder + decoder) でマスクプロポーザルを生成
  - OVSeg の backbone → pixel decoder → transformer decoder 相当を SAM3 1モデルに統合
- CLIP ViT-L/14 で各マスク領域を分類（sam3とは独立）
- SAM3 は frozen
- 分類器の重み: OV-Seg の学習済み Mask Prompt 重みを流用

---

== 目的

OVSeg（MaskFormer + CLIP）のマスク生成部分を SAM3 に置き換え、SAM3 マスクプロポーザルを CLIP で分類する

#v(1em)
#align(center, [$"Input" arrow "SAM3 (200 queries)" arrow "CLIP ViT-L/14" arrow "Segmentation"$])

---

== 構成

#columns(2, gutter: 2em)[
  - マスク生成: SAM3 decoder（200 query）
  - マスク分類: CLIP ViT-L/14
    - 各マスク領域を 224×224 にリサイズ
    - backbone → テキスト特徴と内積
  - 分類器の重み: OVSeg の Mask Prompt Tuning 済み weights を流用
  - SAM3 の重み: HuggingFace（facebook/sam3）からダウンロード

  #colbreak()
  #figure(
    image("images/arm_maskformer_backbone.png", height: 40%),
    caption: "maskformerをbackboneにした場合",
  )
  #figure(
    image("images/arm_sam3_backbone.png", height: 40%),
    caption: "sam3をbackboneにした場合",
  )
]

---

== 結果

#table(
  columns: (auto, auto, auto, auto, auto),
  stroke: 0.5pt + luma(200),
  inset: (x: 6pt, y: 4pt),
  table.header([*method*], [*backbone(特徴抽出器)*], [*head(分類器)*], [*training data*], [*ADE20K-150*]),
  [OVSAM3 (ours)], [SAM3 encoder], [fine-tuned CLIP], [COCO-Stuff-171], [*25.677*],
  [OVSeg], [Swin-B], [fine-tuned CLIP], [COCO-Stuff-171], [29.6],
  [OVSeg], [R101-c], [fine-tuned CLIP], [COCO-Stuff-171], [24.8],
  [SAM3], [SAM3 encoder], [SAM3 decoder], [SA-Co], [39.0],
)

#v(0.5em)
※ OVSAM3 の分類器は OVSeg 由来の fine-tuned CLIP 重みをそのまま流用。OVSAM3 用の追加 fine-tuning は未実施。

ピュアsam3の性能が高すぎるので、こっちを軸足に移していきたい

---

= まとめ

---

#columns(2, gutter: 2em)[
  進捗
  - MaskFormer の切り出し品質がボトルネックと確認
  - SAM3 置換のアーキテクチャ設計完了 ($lambda=0$ で fusion 問題解決)
  - OVSAM3 実装・評価完了: A-150 = 25.677

  #colbreak()

  今後の予定
  - sam3ベースのモデルに切り替えていく
  - 階層的セグメンテーションへの拡張
  - 研究計画書に沿った方向性の具体化
]
