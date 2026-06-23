#import "@preview/touying:0.6.1": *
#import themes.metropolis: *
#import "@preview/numbly:0.1.0": numbly
#import "@preview/presio:0.1.0": media
#import "@preview/mmdr:0.2.2": mermaid
#import "@preview/cheq:0.2.2": checklist


#set heading(numbering: numbly("{1}.", default: "1.1"))
#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  config-info(
    title: [Spatial Relation Search in 3D Scenes],
    author: [Kenichiro Goto],
    date: "2026-06-23",
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


#show link: set text(fill: blue)
#set page(background: image("images/owl_and_fox.png"))
#title-slide()[]
#set page(background: image("images/presentation_background.png"))


---

= おさらい

---

== LangSplat (CVPR 2024 Highlight)#footnote[https://langsplat.github.io/]

#grid(
  columns: (2fr, 2fr),
  column-gutter: 2em,
  [
    #figure(
      image("images/langsplat_pipeline.png"),
      caption: "パイプライン",
    )
  ],
  [
    #figure(
      image("gifs/langsplat.gif"),
      caption: "検索の様子",
    )
  ],
)

3D Gaussian Splatting の各ガウシアンに CLIP の言語特徴量を埋め込んで、自然言語で3Dシーン内の物体領域を特定できるようにした手法。

- 既存の NeRF ベース手法（LERF）より約199倍速い（0.26秒 vs 7.77秒/クエリ）
- SAM の階層マスク（whole/part/subpart）を使って CLIP の密予測タスクの弱さを解決
- シーン固有の autoencoder で 512次元→3次元に圧縮してメモリを節約（弱点でもある）

#text(weight: "bold")[できること] / [できないこと]

- できること: 「コップ」や「机」といった単一物体の検索。検索可能な名詞の範囲は CLIP と同じはず
- できないこと: 「机の上のコップ」など位置関係や属性を含む検索
  - 各ガウシアンが独立に「自分はクエリテキストとどれだけ一致するか」を計算するだけで、物体同士の関係性を見る仕組みがない

---

== Rel3D (NeurIPS 2020 Spotlight)#footnote[https://github.com/princeton-vl/Rel3D]

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

= 進捗報告

---

== 提案パイプライン

1. クエリからCLIPに登録されている名詞, Rel3Dで定義されている関係をパース
2. LangSplatのエンコーダーに入れて出力の座標を得る
3. 座標から相対ベクトルを計算（非常に単純だが、とりあえずこれで）
4. Rel3DのMLPに入力して、関係の確率分布を得る
5. LangSplatの出力をフィルタリングして、レンダリング


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
  MLP --> SC[\"score\"]
  SC --> R[\"Rendering\"]
  LLM -- \"relation: on\" --> R",
  ),
  caption: [パイプラインの概観],
)



---

== 進行中

#columns(2)[

  === LangSplat の環境構築

  - CUDA toolkit、pytorch 2.x, CUDA 12.xなどのRTX PRO 6000 Blackwell用の環境設定を行い、LangSplat を動かそうとしている
    - cudaの設定とかは初めてなので少し手間取っている


  === LangSplatV2 (NeurIPS 2025)

  - LangSplatV2 という後継モデルが存在する
    - V1に比べてレンダリング時間が短縮
    - 特徴次元数によらず定数時間でレンダリングできるようになる
  - コードは公開されているが、ライセンスが公開されていないため、現在使用申請中

  #colbreak()

  #figure(
    image("images/langsplat_v2_rendering_time.png", height: 40%),
    caption: [レンダリング時間の比較],
  )
  #figure(
    image("images/langsplat_request_issue.png", height: 40%),
    caption: [LangSplatV2 にissueを立てたが返事はまだきていない],
  )

]


---

== 今後の予定

- [ ] 環境構築(Rel3D側も)
- [ ] 公開チェックポイントで LangSplat / Rel3D を動かし、軽く再現性を確認する
- [ ] その後、自分の提案パイプラインで小さく動かしてみる
  - [ ] LangSplat → Rel3D MLP をつなぐ
- [ ] LangSplat の座標精度は十分か
- [ ] Rel3D の 30 関係ですべてカバーできるか
- [ ] 前後関係・包含関係は座標差だけでは不十分なクエリへの対応を考える
- [ ] LLM によるクエリ分解は本当に必要か

- あと良さげなサイトがあったので一応共有
  - #link("https://paperswithcode.co/")[Papers with Code]
