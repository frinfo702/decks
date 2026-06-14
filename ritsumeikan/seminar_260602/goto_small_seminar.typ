#import "@preview/touying:0.6.1": *
#import themes.metropolis: *
#import "@preview/numbly:0.1.0": numbly

#set heading(numbering: numbly("{1}.", default: "1.1"))
#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  config-info(
    title: [個別ゼミ],
    subtitle: [],
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



= MedDINOv3: How to adapt vision foundation models for medical image segmentation?

---

== TL;DR

DINOv3 (Meta)を医療画像セグメンテーションに適用するシンプルなフレームワーク。元のViT にマルチスケールトークン集約を加え、387万枚の CT スライスでドメイン適応的に事前学習し、4 ベンチマークで SOTA 同等以上を達成。

---

== 弱点

MedDINOv3は、自然画像で学習された基礎モデルを医療領域に適応させる過程でいくつかの弱点が露呈している

- ドメインギャップとデータ収集コスト
  - 自然画像で学習されたDINOv3は、医療画像との間に大きなドメインギャップがある。これを埋めるため、MedDINOv3は387万枚ものCTスライスからなる独自の大規模データセット（CT-3M）を用いた3段階のドメイン適応事前学習を行っていますが、莫大な計算リソースとデータ収集コストを要する
- 3D空間的文脈の欠如
  - MedDINOv3はあくまで2Dのスライスごとに最適化されたフレームワークであり、臓器や病変の3次元的な広がりや連続性を捉えるのが苦手
- ViTの局所的特徴抽出の弱さと計算オーバーヘッド
  - ViTはCNNに比べて局所的なテクスチャや境界線を捉えるのが苦手です。これを補うために、MedDINOv3は896×896といった超高解像度での学習を強制していますが、これが推論時のメモリ消費と計算コストを著しく増大させている
- 腫瘍セグメンテーションへの弱さ
  - 肝臓や腎臓といった「正常臓器」の分割ではCNN（nnU-Net）を上回るSOTAを達成した一方、形状やサイズ、テクスチャの個体差が極めて大きい「腫瘍」のセグメンテーションでは、専門化されたCNNと同等の性能に留まっている

---

== 弱点を補う研究例

- VISTA3D (CVPR 2025)
  - 3D空間的文脈の欠如を補完
- MM-DINOv2 (MICCAI 2025)
  - ドメインギャップを補完
- Adapting Vision Foundation Models for Real-Time Ultrasound Image Segmentation (MICCAI 2025)
  - 高計算コストと特定モダリティ（超音波）への不適合を補完
- DINOv3 with Test-Time Training for Medical Image Registration (SPIE Medical Imaging 2026)
  - 事前学習データ（CT-3M等）にない未知の症例への適応力を補完
- Task-Specific Knowledge Distillation from the Vision Foundation Model (MICCAI 2024)
  - ViTの推論オーバーヘッドとドメインギャップを補完

---

== 今なお残る課題

- 腫瘍・病変のセグメンテーション
  - nnU-Netと同レベルで他のタスクより弱い
  - 腫瘍は症例ごとに形状、サイズ、内部の壊死や石灰化のテクスチャが全く異なり、この病理的な不均質性を捉えるのが難しい
- 細胞・組織レベルでの微細なセグメンテーション
  - ViTベースのモデルなのでマクロな臓器の位置関係には強いものの、病理全スライド画像（WSI）や電子顕微鏡レベルの微細な細胞パターンやテクスチャを捉えるのが極端に苦手
- 精度と推論コストのトレードオフ
  - ViTの局所受容野の弱さを補うためのマルチスケール特徴集約や高解像度入力は、精度向上には寄与するものの、臨床現場の一般的なGPU環境でリアルタイムに3Dボリュームを推論するにはコストが高すぎる


---

= SkySense: A Multi-Modal Remote Sensing Foundation Model Towards Universal Interpretation for Earth Observation Imagery (CVPR 2024)

---

== TL;DR

- 通常のカメラ（光学RGB）、目に見えない波長（マルチスペクトル）、雲や夜間も見えるレーダー（SAR）のマルチモーダル
- 地形・建物・森林・水域などのパターンや空間関係をすでに熟知している
- 災害用, 農業用などタスクに依存しない高い汎用性を持つ
- 武汉大学(Wuhan University) とAnt Groupの共同研究

---

== 弱点

1. パラメータの利用が冗長
  - 高解像度光学画像（Swin-H）、マルチスペクトル（ViT-L）、SAR（ViT-L）に別々のバックボーンを使用。合計12.6億パラメータと冗長
2.  自然画像向けSSLの適用限界
3. 解像度差異への対応の複雑さ
  - 異なる地上サンプル距離（GSD）を持つモダリティを同時処理する際、特徴量の空間整合を保つ仕組みが複雑
4. モダリティ固有特徴が失われる
  - 汎用性を持たせるために各モーダルにおいてパラメータ完全共有している。各センサー固有の物理的特性（波長・偏波など）の表現が損なわれる

---

== 弱点を補う研究例

- SkySense V2（ICCV 2025)
  - 前述の1, 3, 4を解決
    - 単一バックボーンに変更など
    - MoEアーキテクチャ
- SkySense-CCS (SPIE 2024)
  - 雲検出特化

---

== 今なお残る弱点

- 計算リソースの膨大さ
- 言語モダリティの統合
- ゼロショット性能
- リアルタイム処理

---

= 今後

- まだ手をつけれるほど落とし込めていないので、もう少しタスクを見極めたい
- やり方が合ってるのか
