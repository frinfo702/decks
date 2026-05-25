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
    date: "2026-05-11",
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
#show link: set text(fill: blue)


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

= 追試進捗

---

== 推論

CLIPで規定されている#link("https://github.com/openai/CLIP/blob/main/data/prompts.md")[template]に従った

#figure(
  image("images/bicycle_comparison.png"),
  caption: [切り出される領域の形は変化していない],
)

OV-Segの推論過程では
1. ラベルをつけずにオブジェクトを切り出すMask生成
2. 切り出されたオブジェクトとクエリを照合する
という流れなので切り出されたエリア形状が変わらないのは実装上当然のことだった
CLIPの限界とは言えない

---

= まとめ

---

#columns(2, gutter: 2em)[
  分かったこと・進捗
  - MaskFormerの切り出し性能がボトルネックになっている
  - (コーディング自体の勉強をしていた)

  #colbreak()

  今後
  - もっと他のデータセットに対してもevaluationを得る
  - 純粋プロンプトマスクを入力とした時のattentionマップを得る
  - 改良版や参照先の論文を見ていく
  - OV-Segの論文と実装の対応づけ
  - 各モジュールの論文を見る

]
