#import "@preview/touying:0.6.1": *
#import themes.metropolis: *
#import "@preview/numbly:0.1.0": numbly
#import "@preview/presio:0.1.0": media
#import "@preview/mmdr:0.2.2": mermaid // https://typst.app/universe/package/mmdr/

#set heading(numbering: numbly("{1}.", default: "1.1"))
#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  config-info(
    title: [個別ゼミ  3D情報検索と位置関係],
    author: [Kenichiro Goto],
    date: "2026-06-08",
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

// intro

---

= LangSplat (CVPR 2024 Highlight)#footnote[https://langsplat.github.io/]

---

== 概要

#media(
  read("images/langsplat_1.png", encoding: none),
  name: "langsplat_overview",
  placeholder: image("images/langsplat_1.png"),
  height: 55%,
)

3D Gaussian Splatting の各ガウシアン#footnote[ガウシアン: 空間上の点（中心+広がり）に不透明度と色を乗せたデータ。点群が離散的な点の集まりなのに対し、各ガウシアンは広がりを持つため、重ねてレンダリングすると穴のない連続的な画像が得られる。]に CLIP の言語特徴量を埋め込んで、自然言語で3Dシーン内の物体領域を特定できるようにした手法。

- 既存の NeRF ベース手法（LERF#footnote[https://www.lerf.io/]）より約199倍速い（0.26秒 vs 7.77秒/クエリ）
- SAM の階層マスク（whole/part/subpart）を使って CLIP の密予測タスクの弱さを解決している
- シーン固有の autoencoder で 512次元→3次元に圧縮してメモリを節約 (弱点でもある)


---

== 入出力

#figure(
  image("images/langsplat_mermaid.png"),
)
---

== できること/できないこと

できること
- 「コップ」や「机」といった単一物体の検索。
- 検索可能の名詞の範囲はCLIPと同じはず

できないこと
- 「机の上のコップ」など位置関係や属性を含む検索
  - LangSplat は各ガウシアンが独立に「自分はクエリテキストとどれだけ一致するか」を計算するだけで、物体同士の関係性を見る仕組みはない。
  - たとえば「机の上にあるコップ」とクエリしても、机とコップが両方ヒットして, 机の下に置いてある別のコップとの区別もつかない。

---

= Featurising Pixels from Dynamic 3D Scenes with Linear In-Context Learners (CVPR 2026 Oral) #footnote[https://lila-pixels.github.io/]

a.k.a LILA

---

== 概要

#columns(2, gutter: 2em)[
  #figure(
    image("images/lila_overview.png"),
  )

  #colbreak()

  - 既存の視覚基盤モデル DINOv2 は画像をパッチ単位で粗く見ており、物体境界や動きの情報が不足している。
  - LILA は、DINOv2 エンコーダは凍結したままデコーダを追加し、パッチ単位の特徴量をピクセル単位の密な特徴マップにアップサンプリングする手法。

  - 学習の核は *Linear In-Context Learning* であり、隣接2フレームのうちコンテキストフレームから depth / optical flow  への線形写像を求め、その同じ写像がクエリフレームでも成立するように最適化する。
    - これにより、時間的一貫性と幾何的緻密さを備えたピクセル表現が得られる。
    - 推論時は単一画像だけで動作する。
    - depth: 画像内のオブジェクトの深度。画像からモデルで推定
    - optical flow: 連続するフレーム間で各ピクセルがどこに動いたかを2次元の移動ベクトルで表現したもの。専用モデルで推定する

]

---

== 入出力

#figure(
  image("images/lila_mermaid.png"),
)

- DPT（Dense Prediction Transformer）は、Vision Transformer のエンコーダが出力した粗い特徴量をピクセル単位の密な出力にアップサンプリングするデコーダ
- 単一画像に対して推論するが、それをつなぎ合わせた結果も前述のLinear In-Context Learningにより滑らか

---

= 位置関係を含んだ検索

---

共にそのままでは物体同士の位置関係は扱えない。

- LangSplatは名詞だけの処理しかできない
- LILAはテキストを入力に受け取れない


e.g.
- 「机の上のリンゴ」
- 「ソファの隣のクッション」
- 「本棚の一番下の棚にある本」

こういうクエリで 3D シーン内の該当領域を検出したい。なお、「熟れたリンゴ」とか「青いリンゴ」みたいな属性検索は今回はスコープ外で、位置関係だけに絞る。属性は SAM が勝手に処理してしまう可能性もある?。

---

== 位置関係の種類


#table(
  columns: (auto, auto, auto),
  stroke: 0.5pt + luma(200),
  inset: (x: 6pt, y: 4pt),
  table.header([*関係*], [*例*], [*3Dでの扱いやすさ*]),
  [`on` （〜の上に接触）], [机の上のコップ], [簡単?（座標の情報が割とそのまま答え）],
  [`above` （〜の上方）], [テーブルの上のランプ], [同上],
  [`below` （〜の下方）], [机の下の椅子], [同上],
  [`next to` （〜の隣）], [ソファの隣のテーブル], [中程度（距離閾値の問題）],
  [`in front of` / `behind`], [テレビの前のリモコン], [難しそう（視点依存、遮蔽）],
  [`inside` （〜の中）], [冷蔵庫の中の牛乳], [難しそう],
)

`on` / `above` / `below` などは 3D 座標だけでどうにかなるかもしれないが、問題は前後関係と包含関係で、これはシーン理解が必要

---

== 懸念

3D シーン + 空間関係アノテーション付きのデータセットがあるのか？

- ScanNet++ #footnote[https://scannetpp.mlsg.cit.tum.de/scannetpp/]: 屋内RGB-Dシーン画像 + インスタンスセグメンテーション。でも空間関係アノテーションはない
- 3DSSG #footnote[https://3dssg.github.io/] (CVPR 2021): ScanNet ベースで空間関係アノテーションあり
- Rel3D　#footnote[https://github.com/princeton-vl/Rel3D] (NeurRIPS 2020) : 物体ペアの空間関係データセット
- あとは合成データ（シミュレータ）で作る手もあるが、難しそう

「机の上のコップ」は人間には自明だけど、机のすぐ横に台があってその上にあるコップはどうするのか。

VLM がそもそも空間関係をどの程度理解できているのかも未知数。CLIP で「on」ってどのくらいわかってるんだろう。


---

= まとめ

---

#columns(2, gutter: 2em)[
  == 進捗

  - 「3D シーン内の位置関係を含む情報検索」って研究としてどうか？

  #colbreak()

  == 今後

  - アプローチとしてはどうですか？
  - 良さそうなら、テキストと位置の関係をどう組み込むかという部分にシンプルなアプローチを考える
  - それぞれの論文紹介
]

---

= 参考

---

- *LangSplat*: #link("https://langsplat.github.io/")[official page]
- *LILA*: #link("https://lila-pixels.github.io/")[official page]
- *3DSSG*: #link("https://3dssg.github.io/")[3dssg.github.io]
