#import "@preview/touying:0.6.1": *
#import themes.metropolis: *
#import "@preview/numbly:0.1.0": numbly
#import "@preview/presio:0.1.0": media
#import "@preview/cheq:0.2.2": checklist

#set heading(numbering: numbly("{1}.", default: "1.1"))
#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  config-info(
    title: [全体ゼミ],
    subtitle: [OV-Seg から空間関係検索へ — 方向性の模索],
    author: [Kenichiro Goto],
    date: "2026-06-15",
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
#show: checklist

// title
#show link: set text(fill: blue)
#set page(background: image("images/blue_whale.png"))
#title-slide()[]
#set page(background: image("images/presentation_background.png"))


---

= 経緯

---

== ドメイン特化の探索

汎用的な能力ではSAM3が圧倒的だったので、新規性を出すためにまずドメインを絞ることを考えた

#columns(2, gutter: 2em)[
  #text(weight: "bold", size: 15pt)[医療画像]

  - 病変・臓器のテキストプロンプト検出
  - nnU-Net (gold standard), MedDINOv3, Tri-Plane Mamba
  - BraTS, MoNuSeg などデータセット
  - 専門家注釈・医学書テキストが OV-Seg と相性良さそう

  #colbreak()
  #text(weight: "bold", size: 15pt)[衛星画像]

  - 地形・物体のオープンボキャブラリー分類
  - SAMGeo, SkySense, RemoteCLIP
  - SpaceNet / DeepGlobe / xBD
  - 超高解像度画像の効率的処理が課題
]

ここから2次元セグメンテーションから離れることを考えた

---

= LangSplat (CVPR 2024 Highlight)

---

== 概要

#media(
  read("images/langsplat_1.png", encoding: none),
  name: "langsplat_overview",
  placeholder: image("images/langsplat_1.png"),
  height: 55%,
)

3D Gaussian Splatting の各ガウシアンに CLIP 言語特徴量を埋め込み、自然言語で 3D シーン内の物体領域を特定。
- NeRF ベース手法（LERF）より約 199 倍高速（0.26s vs 7.77s/query）
- SAM 階層マスク (whole/part/subpart) で CLIP の密予測弱さを解決
- シーン固有 autoencoder で 512次元→3次元に圧縮 (弱点でもある)

---

== できること / できないこと

できること:
- 「コップ」「机」など単一物体の検索（CLIP の語彙範囲内）

できないこと:
- 「机の上のコップ」など位置関係・属性を含む検索
  - 各ガウシアンが独立に類似度計算するだけで物体間関係を考慮しない
  - 机の上下どちらのコップか区別できない

---

== 問題設定

LangSplat, LILA 共にそのままでは物体間の位置関係を扱えない。
- LangSplat: 名詞単体の処理のみ
- LILA: テキスト入力を受け取れない

e.g.
- 「机の上のリンゴ」「ソファの隣のクッション」「本棚の一番下の棚にある本」

こうしたクエリで 3D シーン内の該当領域を検出したい。

---

== 位置関係の種類

#table(
  columns: (auto, auto, auto),
  stroke: 0.5pt + luma(200),
  inset: (x: 6pt, y: 4pt),
  table.header([*関係*], [*例*], [*3Dでの扱いやすさ*]),
  [`on` / `above` / `below`], [机の上のコップ], [簡単（座標情報がそのまま使える）],
  [`next to`], [ソファの隣のテーブル], [中程度（距離閾値の問題）],
  [`in front of` / `behind`], [テレビの前のリモコン], [難しい（視点依存・遮蔽）],
  [`inside`], [冷蔵庫の中の牛乳], [難しい（シーン理解が必要）],
)

---

== 利用可能なデータセット

- ScanNet++: 屋内 RGB-D シーン + インスタンスセグメンテーション。空間関係アノテーションなし
- 3DSSG (CVPR 2021): ScanNet ベースで空間関係アノテーションあり
- Rel3D (NeurIPS 2020): 物体ペアの空間関係データセット

VLM が空間関係をどの程度理解できているのかも未知数。

---

= まとめ

---

== 進捗

- [x] OV-Seg 追試・SAM3 置換評価完了
- [x] 医療・衛星ドメイン調査
- [x] MedDINOv3, SkySense レビュー
- [x] LangSplat, LILA レビュー
- [x] 「3D シーン内の位置関係を含む情報検索」の検討
- [ ] 位置関係を含んだクエリをパースする機構を追加
  - まずは2つのオブジェクトから
- [ ] Rel3Dを読む
- [ ] データセットの模索、検討
