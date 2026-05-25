#import "@preview/touying:0.6.1": *
#import themes.metropolis: *
#import "@preview/numbly:0.1.0": numbly

#set heading(numbering: numbly("{1}.", default: "1.1"))
#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  config-info(
    title: [個別ゼミ],
    subtitle: [OV-Seg 進捗],
    author: [Kenichiro Goto],
    date: "2026-04-28",
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
#set page(background: image("images/blue_whale.png"))
#title-slide()[]
#set page(background: image("images/presentation_background.png"))

= Open-Vocabulary Segmentationとは

---

== 問題設定: Open-Vocabulary Segmentation
#columns(2, gutter: 2em)[
  Close-Vocabulary Segumentation

  - 事前に決められたクラス（例: car, person, tree）だけをラベルづけする
  - 自然言語でのマッチは不可能 (例: flying drone flying at high altitude)

  Open-Vocabulary

  - 画像中の領域をテキストによる自由な説明（例: 'red convertible car' 'large white cloud')にマッチさせたい
  - そのテキストクラスは訓練時には見ていなくてもいい (training-free)

  #colbreak()
  #figure(
    image(
      "images/The-segmentation-results-comparison-of-the-closevocabulary-and-open-vocabulary.png",
      width: 100%,
      height: 70%,
      fit: "cover",
    ),
    caption: [The segmentation results comparison of the closevocabulary and open-vocabulary segmentation.#footnote[https://www.researchgate.net/figure/The-segmentation-results-comparison-of-the-closevocabulary-and-open-vocabulary_fig5_390405782]],
  )
]

---

= OV-Seg (Liang et al., 2023)

---

== OV-Seg
#columns(2, gutter: 2em)[
  === 主流アプローチのボトルネックを検証
  1. マスク生成（クラス非依存）
  2. マスク領域のテキスト分類
    - 事前学習済みのVLM（例：CLIP）で、マスクされた領域画像を入力し、テキストラベルを割り当てる。

  $arrow$ CLIPは”自然な全体画像”が前提なので背景が抜け落ちたマスク付き画像を上手く扱えない
  #colbreak()
  #figure(
    image(
      "images/overview-exsiting-method.png",
      fit: "cover",
    ),
    caption: "OV-Seg以前に主流だった2段階アプローチ",
  )
]

---
== 提案手法1：Mask-adapted CLIP
#columns(2, gutter: 2em)[
  - CLIP を*マスク付き画像に強いモデル*に変える
  - 既存のキャプションデータセットを用い、CLIP を使ってマスク領域の画像とキャプション中の名詞をマッチングさせたペアを作成し擬似訓練データを自動作成
    - マスク情報が載ったデータを作成できる
  - それらを使ってCLIPをfine-tuning
  - ノイズは多いが語彙が非常に多様なデータを用いることができる
  #colbreak()
  #figure(
    image(
      "images/how-mask-former-works.png",
      fit: "cover",
    ),
    caption: "region情報の付加されたデータを自動作成",
  )
]

---

== 提案手法2: Mask prompt tuning
- マスク画像のゼロ埋め領域のパッチは CLIP が未学習の「ゼロトークン」になりドメインシフトを起こす
- CLIP の重みを一切*変更せず*、ゼロトークンを学習可能なプロンプトで置き換える

#v(0.5em)
$ "Input" = T ⊙ M_p + P ⊙ (1 - M_p) $

- $T in RR^{N_p times E}$: マスク画像のパッチ埋め込み列。マスク領域はゼロ
- $M_p in {0,1}^{N_p}$: 画像ごとの二値マスク。パッチ内の*全ピクセル*がマスクなら $0$、境界部は $1$
- $P in RR^{N_p times E}$: 学習可能なプロンプトテンソル（*全画像で共通*）
- $⊙$: 要素積。$M_p = 0$ の位置で $T$ を $P$ に置き換える
- Deep prompt: Transformer の入力だけでなく *3層* に挿入
- パラメータ数: ViT-B/16 は $3 times 196 times 512$、ViT-L/14 は $3 times 256 times 768$

#v(0.5em)
#figure(
  image(
    "images/prompt-mask-tuning.png",
    height: 40%,
  ),
  caption: "prompt mask tuningの様子. 学習されるのはmask promptのみ (CLIPも学習させると性能はさらに上がる)",
)

---


=== mask promptの可視化

#figure(
  image("images/mask-prompt-visualization.png"),
  caption: [mask promptを可視化してみた様子。視覚的に解釈可能性はなさそう #footnote[テンソルに逆行列をかけてdecodeした]],
)


---

= 追試進捗

---

== 追試: Oculusを言い換え
#grid(
  columns: (1fr, 1fr),
  gutter: 1.5em,
  [
    #image("images/0.png", fit: "cover")
    #v(0.5em)
    #text(weight: "bold")['Oculus' 'Ukulele']
  ],
  [
    #image("images/1.png", fit: "cover")
    #v(0.5em)
    #text(weight: "bold")['VR headset' 'Ukulele']
  ],
)

---

#let height = 35%
== 追試: 非常に大量のオブジェクト

'dog', 'dogs'間に結果の違いはみられない。また犬種も精度は高くないように見える

#grid(
  columns: (1fr, 1fr),
  gutter: 0.6em,
  [
    #figure(
      image("images/dogs-cover.jpg", height: height),
      caption: "元画像",
    )
  ],
  [
    #figure(
      image("images/2.png", height: height),
      caption: "'dog'",
    )
  ],

  [
    #figure(
      image("images/3.png", height: height),
      caption: "'Labrador Retriever' など多くの犬種名を入力",
    )

  ],
  [
    #figure(
      image("images/7.png", height: 35%),
      caption: "'dogs'",
    )
  ],
)

---

== 追試：少数のオブジェクトで品種を見分けられるか

#columns(2, gutter: 2em)[
  #figure(
    image("images/hamsters.jpg", fit: "cover"),
    caption: "元画像",
  )
  #colbreak()
  #figure(
    image(
      "images/6.png",
      width: 100%,
      height: 70%,
      fit: "cover",
    ),
    caption: "'djungarian' 'campbell' 'hybrid'",
  )
]
#text("こちらも種類は的外れ。classnameはモデルの制約上あまり長くできなかったのでクエリ自体がよくないかも")

---

== 追試: 属性や関係を認識できるか
#let height = 70%
#grid(
  columns: (1fr, 1fr, 1fr),
  gutter: 1.5em,
  [

    #figure(
      image("images/person-holding-black-umbrella.webp", height: height),
      caption: "元画像",
    )
  ],
  [
    #figure(
      image("images/4.png", height: height),
      caption: "'person holding a blue umbrella'",
    )
    #v(0.5em)
  ],
  [
    #figure(
      image("images/5.png", height: height),
      caption: "'person holding a black umbrella'",
    )
  ],
)
人にセグメンテーションして欲しかったが傘が対象になっている。また色の違いも認識できていない

---

= まとめ

---

#columns(2, gutter: 2em)[
  分かったこと・進捗
  - Mask-adapted CLIP + Mask Prompt Tuning の推論追試を実施
  - "dog", "person" など一般的なクラスは概ね検出可能
  - mask promptの可視化を試した

  #colbreak()

  今後
  - 今回見つかった弱点を解決している既存モデルの適用を考える
  - OV-Segの論文と実装の対応づけを完了させる
  - 各モジュールの論文を見る

]
