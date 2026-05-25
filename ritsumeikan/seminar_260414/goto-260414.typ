#import "@preview/touying:0.6.1": *
#import themes.simple: *

#show: simple-theme.with(
  aspect-ratio: "16-9",
  header: none,
  footer: [後藤 個別ゼミ 260414],
)

#set text(font: "Hiragino Kaku Gothic ProN", size: 14pt, lang: "en")
#set par(leading: 0.78em)
#set list(indent: 1.1em, spacing: 0.34em)
#show raw: set text(font: "Geist Mono", size: 13pt)
#show heading.where(level: 1): set text(size: 22pt, weight: "bold")

#let ink = rgb("#111111")
#let accent = rgb("#1d4ed8")
#let muted = rgb("#5f6368")

#let slide-head(title) = [
  #text(size: 22pt, weight: "bold", fill: ink)[#title]
  #v(0.35em)
]

#let claim(body) = block(
  inset: 0pt,
  below: 0.55em,
)[
  #text(size: 24pt, weight: "bold", fill: accent)[#body]
]

#let sub(body) = text(size: 15pt, fill: muted)[#body]

#title-slide()[
  = 後藤 個別ゼミ　OV-Seg
  2026-04-12
]

#slide()[
  = 問題設定：Open-Vocabulary Segmentation

  #grid(
    columns: (1fr, 1fr),
    gutter: 1.2em,
    [
      #figure(
        image("images/The-segmentation-results-comparison-of-the-closevocabulary-and-open-vocabulary.png", height: 60%),
        caption: [The segmentation results comparison of the closevocabulary and open-vocabulary segmentation. #footnote[https://www.researchgate.net/figure/The-segmentation-results-comparison-of-the-closevocabulary-and-open-vocabulary_fig5_390405782]],
      )
    ],
    [
      Close-Vocabulary Segumentationは、事前に決められたクラス（例：車・人・木）だけをラベルづけする

      Open-Vocabulary

      - 画像中の領域を「テキストによる自由な説明（例：『赤いオープンカー』『大型の白い雲』）」にマッチさせたい
      - そのテキストクラスは訓練時には見ていなくてもいい
    ],
  )
]

#slide()[
  = OV-Seg

  #grid(
    columns: (1fr, 1fr),
    gutter: 1.5em,
    [
      === 主流アプローチのボトルネック
      1. マスク生成（クラス非依存）
      2. マスク領域のテキスト分類
        - 事前学習済みのVLM（例：CLIP）で、マスクされた領域画像を入力し、テキストラベルを割り当てる。

      $arrow$ CLIPは”自然な全体画像”が前提なので背景が抜け落ちたマスク付き画像を上手く扱えない
    ],
    [
      #figure(image("images/overview-exsiting-method.png"))
    ],
  )
]

#slide()[
  #grid(
    columns: (1fr, 1fr),
    gutter: 1.5em,
    [
      === 提案手法1：Mask-adapted CLIP
      - CLIP を*マスク付き画像に強いモデル*に変える
      - 既存のキャプションデータセットを用い、CLIP を使ってマスク領域の画像とキャプション中の名詞をマッチングさせたペアを作成し擬似訓練データを自動作成
        - マスク情報が載ったデータを作成できる
      - それらを使ってCLIPをfine-tuning
      - ノイズは多いが語彙が非常に多様なデータを用いることができる
    ],
    [
      #figure(image("images/how-mask-former-works.png"))
    ],
  )
]

#slide()[
  === 提案手法2：Mask prompt tuning
  - マスク画像は背景がなく、切り取られた領域だけであるため、*どのピクセルが背景か*を教えてやると CLIP がうまく動作しやすくなる
  - CLIP の重みを一切変更せずにプロンプト側のテンプレートを調整する

  #v(0.35em)
  #figure(image("images/prompt-mask-tuning.png"))
]

#slide()[
  = 追試：実験設定

  #set text(size: 12pt)

  共通設定：Train = COCO-Stuff-171　　Test = ADE20K-150（val）　　Batch = 32　　Max iter = 120,000　　WarmupPolyLR（warmup 1,500 iter）　　Grad clip = 0.01

  #v(0.4em)

  #table(
    columns: (1.6fr, 1fr, 1fr),
    stroke: 0.5pt + luma(200),
    inset: (x: 7pt, y: 5pt),
    table.header([*項目*], [*Config A*], [*Config B*]),
    [Backbone], [Swin-B（22K, 384×384）], [ResNet-101 DeepLab],
    [CLIP], [ViT-L/14], [ViT-B/16],
    [Embedding dim], [768], [512],
    [Crop size], [640×640], [512×512],
    [Base LR], [`6e-5`], [`2e-4`],
    [Backbone LR mult], [1.0], [0.1],
    [Weight decay], [0.01], [`1e-4`],
    [Mask THR], [0.4], [0.5],
  )
]

#slide()[
  = 結果（ADE20K-150 val）(事前学習済みパラメータ)

  #table(
    columns: (1fr, 1fr, 1fr),
    stroke: 0.5pt + luma(200),
    inset: (x: 8pt, y: 6pt),
    table.header([*Config*], [*mIoU*], [*fwIoU*]),
    [Config A（Swin-B / ViT-L/14）], [29.58], [57.33],
    [Config B（R-101 / ViT-B/16）], [24.87], [52.98],
  )

  #v(0.8em)

  #grid(
    columns: (1fr, 1fr),
    gutter: 1.5em,
    [
      === Config A：IoU 上位
      #table(
        columns: (1fr, auto),
        stroke: 0.5pt + luma(200),
        inset: (x: 6pt, y: 4pt),
        table.header([*クラス*], [*IoU*]),
        [sky], [86.82],
        [toilet], [84.61],
        [pool table], [77.21],
        [person], [76.10],
        [road], [75.05],
      )
    ],
    [
      === Config A：IoU 下位
      #table(
        columns: (1fr, auto),
        stroke: 0.5pt + luma(200),
        inset: (x: 6pt, y: 4pt),
        table.header([*クラス*], [*IoU*]),
        [field], [0.00],
        [pillow], [0.00],
        [kitchen island], [0.00],
        [base / pedestal], [0.00],
        [buffet], [0.00],
      )
    ],
  )
]

#slide()[
  = 追試：モデルの学習
  OVSeg セグメンテーションモデルの学習
  - open-vocab 分類を CLIP 特徴で行う
  - mask 単位で crop した領域を CLIP に通す

  #v(0.35em)
  #figure(image("images/training-progress.png", height: 60%))

  学習途中

]
