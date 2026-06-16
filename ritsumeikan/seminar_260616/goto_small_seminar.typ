#import "@preview/touying:0.6.1": *
#import themes.metropolis: *
#import "@preview/numbly:0.1.0": numbly
#import "@preview/presio:0.1.0": media
#import "@preview/mmdr:0.2.2": mermaid

#set heading(numbering: numbly("{1}.", default: "1.1"))
#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  config-info(
    title: [Spatial Relation Search in 3D Scenes],
    author: [Kenichiro Goto],
    date: "2026-06-16",
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

---

= Rel3D (NeurIPS 2020 Spotlight)#footnote[https://github.com/princeton-vl/Rel3D]

---

== 概要

- 空間関係を 3D でアノテーションした大規模データセット
  - 4,999 シーン / 27,336 画像、67 カテゴリ、30 種類の空間関係
- 各シーンは *minimally contrastive pairs* で構成
  - 写っているオブジェクトなどは同一だが関係だけがテキストラベルとは微妙に異なるペアが作ってある
  - データセットバイアスを低減し、少数サンプルでも効率的に学習可能
  - 本当に位置関係を理解しているのかを検証するデータセットとしても使える
    - 他の指標では例えば"table", "cup"がセットで登場すれば普通上にcupが載っているだろうというような推測を暗黙のうちに学習してしまう（cupが机の裏に張り付いているような画像は自然画像には含まれない）
  #figure(
    image("images/rel3d_samples.png"),
    caption: [minimally contrastive pairsの例],
  )

---

== 3D 特徴量（aligned features）と MLP ベースライン

#columns(2, gutter: 2em)[
  #figure(
    image("images/rel3d_label_image.png"),
    caption: [???],
  )

  #colbreak()

  物体を直方体で近似し、$S_"aligned"$（正面向き・上方向を揃えた座標系）での
  位置・姿勢・サイズで表現。各物体に対して $9$ 次元のベクトル

  - $S_"cam"$ での重心位置 $(x, y, z)$
    - $S_"cam"$: カメラ（視点）基準の座標系 \
  - $S_"aligned"$ での $x y z$ 方向のサイズ $(w, h, d)$
    - $S_"aligned"$: 物体固有の正面・上方向を揃えた正規化座標系
  - $S_"aligned" → S_"cam"$ への回転 $(alpha, beta, gamma)$


  $
    bold(f)_"obj" = (x, y, z, alpha, beta, gamma, w, h, d) in RR^9
  $

  2 物体の特徴量を連結した $18$ 次元が `transform_vector`:

  $
    bold(f) = (bold(f)_"subj", bold(f)_"obj") in RR^18
  $

  これを入力とし、5 層 MLP + skip connection で 30 種類の空間関係を分類する。
]

---

== Rel3Dのラベル

#figure(
  image("images/rel3d_number_of_images_per_predicate.png"),
)

---

= SpatialReasoner (NeurIPS 2025)#footnote[https://spatial-reasoner.github.io/]

- 関連研究としての紹介
- そんなにしっかりと読めていない

---

== 概要

#columns(2, gutter: 2em)[
  #figure(
    image("images/spatialreasoner_overview.png"),
    caption: [先行モデルとの比較],
  )

  #colbreak()

  3D 空間推論のための LVLM(Large Vision-Language Model)。明示的な 3D 表現（位置・向き）を知覚・計算・推論の各段階で共有する点が特徴。

  - Stage I: SFT で明示的 3D 表現の知覚・計算能力を獲得
  - Stage II: RL (GRPO) で未知の質問タイプにも汎化する 3D 思考を学習
  - 3DSRBench で Gemini 2.0 を 9.2% 上回る
]

== 自分の研究との関連

- 空間関係を「明示的な 3D 表現を介して扱う」という思想が共通
- ただし SpatialReasoner は end-to-end の LVLM で、本研究は
  LangSplat + Rel3D MLP によるモジュール型アプローチをとる

---

= 提案アーキテクチャ

---

== パイプライン全体

#v(0.5em)

#figure(
  mermaid(
    "flowchart LR
  Q[\"Query: 'A cup on the table'\"] --> LLM[\"parse (with (L)LM?)\"]
  LLM -- \"subject: cup\" --> LS1[\"LangSplat CLIP query\"]
  LLM -- \"anchor: table\" --> LS2[\"LangSplat CLIP query\"]
  LS1 --> CP[\"cup_positions\"]
  LS2 --> TP[\"table_positions \"]
  CP --> TV[\"transform_vector = mean(cup) - mean(table)\"]
  TP --> TV
  TV --> MLP[\"Rel3D MLP\"]
  MLP --> SC[\"score\"]",
  ),
  caption: [パイプライン全体],
)

---

== 今考えている流れ

=== Step 1: クエリのパース

入力クエリ: "A cup on the table"

```
subject = "cup"
anchor  = "table"
relation = "on"
```

自然言語の位置関係クエリを (subject, anchor, relation) の
三つ組に分解する。テンプレートベースでも可能だと思うのでまずは静的解析で十分だと考えている。
SpatialReasonerのように, 多様な表現に対応するには (L)LM の使用が必要かも


=== Step 2: LangSplat による物体位置の取得

subj / anchor それぞれを CLIP クエリとして
LangSplat に入力し、関連度の高いガウシアンの 3D 座標を取得:

$
  C = {bold(p)_1, bold(p)_2, dots, bold(p)_n} subset RR^3 quad (n: "cupの数") \
  T = {bold(q)_1, bold(q)_2, dots, bold(q)_m} subset RR^3 quad (m: "tableの数")
$

各物体の代表位置は座標の平均を用いる
#v(0.5em)

$
  overline(bold(p)) = 1/n sum_(i=1)^n bold(p)_i
$ \
$
  overline(bold(q)) = 1/m sum_(j=1)^m bold(q)_j
$


=== Step 3: 相対ベクトルの計算と関係判定

#v(0.5em)
$ bold(v) = overline(bold(p)) - overline(bold(q)) $
#v(0.5em)

このベクトルを Rel3D の MLPに入力し、
各関係クラスの確率($"score"$)を出力

$ "score" = P("relation" = "on" | bold(v)) $

しきい値以上ならその関係が成立していると判定する。

---

== Rel3D のMLP がそのまま使えるのか？

#figure(
  image("images/rel3d_success_and_failure_cases.png"),
  caption: [objectの位置を変化させた場合に位置関係が「クエリに整合しているか」を可視化したもの。青が整合を意味する。MLPの出力をもとに、閾値0.5の2クラス分類をした結果],
)


Rel3D の `transform_vector` は物体間の相対位置・姿勢を $18$ 次元にエンコードしたもので、LangSplat から得られる座標差ベクトルと*同じ形式*。

Rel3D の MLP ベースラインが関係判定モジュールとしてそのまま流用できる。

ただし 3D 特徴量だけでは不十分とRel3Dの論文で指摘がある。物体形状を直方体で近似しているため、TV の下のボールなど形状依存の関係は苦手。

---

= まとめ

---

== 進捗と今後

#columns(2, gutter: 2em)[
  == 進捗

  - Rel3D と SpatialReasoner（一部） の調査
  - LangSplat → Rel3D MLP をつなぐ
    パイプラインの具体化

  #colbreak()

  == 課題・検討点

  - 今回提案したアーキテクチャの妥当性を見直した上で、良さそうなら作ってみる
    - LangSplat の座標精度は十分か
    - Rel3D の 30 関係ですべてカバーできるか
    - 前後関係・包含関係は座標差だけでは不十分
  - LLM によるクエリ分解は本当に必要か
]
