#import "@preview/touying:0.6.1": *
#import themes.metropolis: *
#import "@preview/numbly:0.1.0": numbly
#import "@preview/presio:0.1.0": media

#set heading(numbering: numbly("{1}.", default: "1.1"))
#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  config-info(
    title: [全体ゼミ],
    subtitle: [OV-Seg → OVSAM-Seg 進捗 \ #link("https://github.com/frinfo702/ov-seg/pull/1")],
    author: [Kenichiro Goto],
    date: "2026-05-25",
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


= これまでの経緯

---

== OV-Seg の追試と課題発見

#columns(2, gutter: 2em)[
  #text(weight: "bold", size: 15pt)[これまでの進捗]

  - OV-Seg (Liang et al., 2023) の追試を実施
    - Config A: 29.58 mIoU (Swin-B / ViT-L/14)
    - Config B: 24.87 mIoU (R-101 / ViT-B/16)
    - 論文結果を再現確認できた

  - 様々な定性評価を実施
    - "Oculus" → "VR headset" で検出改善
    - 犬種・ハムスター品種の識別は困難
    - 色・属性の認識も不正確

  どれも背景が欠落したマスクのみの画像では文脈情報が不足

  #colbreak()
  #figure(
    image("images/ov-seg-result-examples.png"),
    caption: "OV-Seg のセグメンテーション結果",
  )
]

---

== MaskFormer の限界

#columns(2, gutter: 2em)[
  #text(weight: "bold", size: 15pt)[ボトルネックはマスク生成]

  - MaskFormer はマスク形状精度が不十分
    - クエリによらずマスク形状が変化しない
    - 推論過程: ラベルなしで領域を切り出す → CLIPで分類
      - CLIP image enc にラベルなしの領域画像を渡す
      - CLIP text enc にqueryを渡す
      - MaskFormerとfine tuning済みCLIPは獲得した表現の幾何的な配置が似るように学習されているので、内積をとると類似度が出る
    - 切り出し品質が分類性能の上限を決定

  - 改善には MaskFormer 自体の置き換えが必要と判断

  #colbreak()
  #figure(
    image("images/bicycle_comparison.png"),
    caption: "切り出される領域の形が変化しない（260511 発表より）",
  )
]


= MaskFormerをSAM3 へ置き換えることを試みる

---

== SAM3 (Meta AI, 2025)

#columns(2, gutter: 2em)[
  SAM3 は Promptable Concept Segmentation 用モデル

  - テキストプロンプトで物体を検出・セグメンテーション
  - 高品質マスクプロポーザルを生成
  - 超巨大なSA-Co データセットで学習
    - 様々なベンチマークでSOTA

  #media(
    read("images/player.gif", encoding: none),
    name: "player.gif",
    placeholder: image("images/player.gif"),
    height: 40%,
  )

  #colbreak()
  #media(
    read("images/sam3_dog.gif", encoding: none),
    name: "demo.gif",
    placeholder: image("images/sam3_dog.gif"),
    height: 40%,
  )
  #media(
    read("images/sa_co_dataset.jpg", encoding: none),
    name: "sa_co_dataset.jpg",
    placeholder: image("images/sa_co_dataset.jpg"),
    height: 40%,
  )

]

---

== 特徴を合成する計算の問題 (Fusion)

MaskFormerをSAM3に置き換えるには両者のアーキテクチャの差を吸収しないといけない

- MaskFormer: MaskFormer がマスク + 埋め込みベクトルを生成 → CLIP 特徴と合成
  - $s = lambda s_"mask" + (1-lambda) s_"clip"$
- SAM3: マスクのみ生成（埋め込みベクトルなし）
  - 次元が合わず合成の計算ができない
  - $s = lambda s_"sam3" + (1-lambda) s_"clip"$

#v(1em)
#text(weight: "bold", size: 16pt, fill: blue)[解決策: $lambda = 0$]

- $lambda = 0$ にすれば CLIP 単独で分類可能
- fusionをそもそもしない
- SAM3 のマスクを直接 CLIP ViT-L/14 で分類
- (adapterを導入するのはどうかと思ったが, concatでいいのではという意見ももらった)

---

== 提案: OVSAM-Seg アーキテクチャ


#v(1em)
$bold("Input") arrow "SAM3 (200 queries)" arrow "CLIP ViT-L/14 (各マスク分類)" arrow bold("Segmentation")$

- SAM3 (encoder + decoder) でマスクプロポーザル生成
  - OVSeg の backbone $arrow$ pixel decoder $arrow$ transformer decoder を統合
- CLIP ViT-L/14 で各マスク領域を分類して類似度を測る
- SAM3 は frozen❄️
- 分類器の重み: OV-Seg 学習済み Mask Prompt 重みを流用❄️

#figure(
  image("images/ov-seg_mask_processing.png"),
  caption: "Maskを生成して、セグメンテーションされる様子",
)
---


#figure(
  image("images/ovseg_overview.png"),
  caption: "OV-Segのアーキテクチャ。このMaskFormerの部分をSAM3で置換する",
)

---

= 実装

---

== OVSAMSeg モデル



推論フロー
1. SAM3 でマスクプロポーザル生成 (max 200)
2. CLIP で各マスクを分類 (softmax)
3. セグメンテーションマップを作成

評価のみ想定（学習は未実装）

---


= 結果と考察

---

== 実験結果

#text(weight: "bold", size: 15pt)[ADE20K-150 val での比較]

#table(
  columns: (auto, auto, auto, auto, auto),
  stroke: 0.5pt + luma(200),
  inset: (x: 6pt, y: 4pt),
  table.header([*method*], [*backbone*], [*head*], [*training data*], [*ADE20K-150*]),
  [OVSAM3 (mine)], [SAM3 encoder], [fine-tuned CLIP], [COCO-Stuff-171], [*25.677*],
  [OVSeg], [Swin-B], [fine-tuned CLIP], [COCO-Stuff-171], [29.6],
  [OVSeg], [R101-c], [fine-tuned CLIP], [COCO-Stuff-171], [24.8],
  [SAM3], [SAM3 encoder], [SAM3 decoder], [SA-Co], [*39.0*],
)

1. OVSeg R101-c (24.8) < OVSAM3 (25.677) < Swin-B (29.6)
2. 分類器は OVSeg 由来の fine-tuned CLIP 重みをそのまま流用（追加 fine-tuning なし❄️）
3. SAM3 単体 (39.0) が圧倒的に高い → 分類器とのミスマッチが原因
4. SAM3 のマスク品質は高いが、CLIP がそれを使いこなせていない

---

== デモの結果

queryとして `A photo of {arm}` を渡した場合
#figure(
  image("images/arm_maskformer_backbone.png", height: 35%),
  caption: "MaskFormer を backbone にした場合",
)
#figure(
  image("images/arm_sam3_backbone.png", height: 35%),
  caption: "SAM3 を backbone にした場合",
)
---

== 考察

なぜ OVSAM3 は SAM3 単体に届かないのか

#text(weight: "bold", size: 15pt)[仮説]

- MaskFormer 用に fine-tune された CLIP が SAM3 の多様なマスク形状に未対応
- 元のOV-SegMaskFormer+CLIPと違い、SAM3+CLIPでは幾何的に配置が似るようにできていないので、内積が高いところが類似度とは言えない可能性がある
- OV-SegのCLIPをそのままSAM3に置き換えてMaskFormerとCLIPのfine tuningをやり直せば改善余地はあるかも



= まとめ

---

#columns(2, gutter: 2em)[
  #text(weight: "bold", size: 18pt)[進捗]

  - MaskFormer の切り出し品質がボトルネックと確認
  - SAM3 置換のアー ($lambda=0$ で fusion 問題解決)
  - `OVSAMSeg` モデル実装
  - `SAM3ProposalGenerator`: 3バックエンド対応
  - 評価スクリプト・デモスクリプト整備
  - Ruff / Mypy / BasedPyright によるコード品質基盤
  - OVSAM3 評価完了: A-150 = 25.677 mIoU

  #colbreak()

  #text(weight: "bold", size: 18pt)[今後の予定]
  - SAM3 単体の性能が既に SOTA (39.0)
  - 階層的セグメンテーションを見据えているのでSAM3の上で構築するのがいい気がしている
  - データが足りない状況でのmask prompt tuningやVLMを使った擬似データ作成の知見はそのまま活かせそう

]
