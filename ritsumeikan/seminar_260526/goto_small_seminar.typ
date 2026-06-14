#import "@preview/touying:0.6.1": *
#import themes.metropolis: *
#import "@preview/numbly:0.1.0": numbly

#set heading(numbering: numbly("{1}.", default: "1.1"))
#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  config-info(
    title: [個別ゼミ],
    subtitle: [ドメイン特化 OV セグメンテーションへの方向転換],
    author: [Kenichiro Goto],
    date: "2026-05-26",
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

== 先週まで

- OV-Seg 追試を完了し、MaskFormer の限界を確認
- OV-SegのMaskFormerを SAM3 への置き換えて実装・評価
  - ADE20K-150: 25.677 mIoU
  - SAM3 単体が 39.0 と圧倒的に高い
- CLIPとSAM3のミスマッチを解決する手もあったがSAM3ベースで出発したモデル群を探索したくなった



---

== タスクの種類, データセット, 評価指標, モデルを調べている

#columns(2, gutter: 2em)[
  #text(weight: "bold", size: 15pt)[医療画像]

  - タスク
    - 病変・臓器のテキストプロンプト検出など
  - データセット
    - BraTS(MRI, 脳腫瘍), MoNuSeg(病理画像, 細胞核)
    - 病理画像は画像サイズが3 × 50,000 × 50,000のようなサイズ感で線形計算量ベースのモデルを適用する幅があったりする
      - ただ扱っているモデルは少ない
  - モデル
    - nnU-Net(ゴールドスタンダード）, Swin-UMamba, MedDINOv3(3DCT), Tri-Plane Mamba(新基盤)
    - MedSAM や SAM-Med2D などのファインチューニング戦略が参考になる
  - 専門家の注釈や医学書をテキスト化しやすい点が OV-Segからの知見と相性が良さそう

  #colbreak()
  #text(weight: "bold", size: 15pt)[衛星画像]

  - タスク
    - 地形・物体のオープンボキャブラリー分類など
  - データセット
    - SpaceNet / DeepGlobe / xBDなど
  - モデル
    - SAMGeo などの地理空間適応手法が参考になる
    - SkySence(大規模な汎用vision model), SAM-RS, RemoteCLIP(VLM)
  - 超高解像度画像の効率的な処理が課題(サイズは病理画像と同じぐらい)
  - 災害時の変化検出など、即応性が求められる
]

---


== 今週のまとめと今後

#columns(2, gutter: 2em)[
  #text(weight: "bold", size: 15pt)[今週やったこと]

  - 医療画像・衛星画像を調査
  - 参考になりそうなモデルを探しながら、気になったものを読んでみている

  #colbreak()
  #text(weight: "bold", size: 15pt)[来週までの予定]

  - ドメインを絞る
  - 追試するなど関係なく感覚を掴むために何かしらミニマルに動かしたい
]
