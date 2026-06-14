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
    subtitle: [OV-Seg から空間関係検索へ],
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

= 3Dシーン情報検索

---

== NeRF vs 3D Gaussian Splatting

NeRFと3D Gaussian Splatting（3DGS）はどちらも複数の2D画像から3Dシーンを再構成する技術だが、シーンの表現方法とレンダリング方式が根本的に異なる

*NeRF* #footnote[https://github.com/bmild/nerf]
ニューラルネットワークを使って3Dシーンを暗示的に表現する。
空間上の任意の点に対して色と不透明度を予測する連続的な関数として機能し、シーン全体をブラックボックス的に学習。
1シーンにつき1つ、以下のような関数を学習する。
- $F(x,y,z,theta,phi)→(R,G,B,sigma)$
  - 入力：3D座標 $(x,y,z)$ + 視線方向 $(theta, phi)$
  - 出力：その点の色 $(R,G,B)$ + 体積密度 $sigma$

#figure(
  image("images/nerf_pipeline.jpg", height: 45%),
)

---

#columns(2)[
  *3DGS* #footnote[https://repo-sam.inria.fr/fungraph/3d-gaussian-splatting/]
  3Dガウシアン（視点によって色が変化する半透明の楕円体）の集合としてシーンを表現する機械学習モデル。
  各ガウシアンには3D座標・色・透明度・共分散の情報が含まれており、ガウシアンをブレンドすることでフォトリアルな画像を生成する。
  まず特徴的な点からSfMという点群を作成する。SfMをガウシアンに変更し、ガウシアンから復元した画像が元画像に近くなるようにガウシアンを変形させたり、複製/分割/削除などの操作を繰り返す
  #figure(
    image("images/3dgs_overview.png"),
    caption: "実際はfigure3のような目標となる線があるわけではないので、再構成の精度で楕円の変形や操作を決定する",
  )

  #colbreak()

  #figure(
    image("images/gaussian_densification.png"),
    caption: "ガウシアンが目標に対して疎なら複製し、逆にはみ出すようなら分割という処理を繰り返す",
  )

]


---

== LangSplat (CVPR 2024 Highlight)#footnote[https://langsplat.github.io/]

#columns(2)[
  #figure(
    image("images/langsplat_1.png"),
  )
  #colbreak()
  #figure(
    image("images/langsplat_pipeline.png"),
  )

]

3D Gaussian Splatting (3DGS) の各ガウシアン#footnote[ガウシアン: 空間上の点（中心+広がり）に不透明度と色を乗せたデータ。点群が離散的な点の集まりなのに対し、各ガウシアンは広がりを持つため、重ねてレンダリングすると穴のない連続的な画像が得られる。]に CLIP の言語特徴量を埋め込んで、自然言語で3Dシーン内の物体領域を特定できるようにした手法。

- 既存の NeRF ベース手法（LERF#footnote[https://www.lerf.io/]）より約199倍速い（0.26秒 vs 7.77秒/クエリ）
- SAM の階層マスク（whole/part/subpart）を使って CLIP の密予測タスクの弱さを解決している
- シーン固有の autoencoder で 512次元→3次元に圧縮してメモリを節約 (弱点でもある)

---


== LERF vs LangSplat

#grid(
  columns: (2fr, 3fr),
  column-gutter: 2em,
  [
    LERF (ICCV 2023)

    #figure(
      image("gifs/output.gif", width: 100%),
      caption: "境界が曖昧なのが見て取れる",
    )
  ],
  [
    LangSplat (CVPR 2024 Highlight)

    #figure(
      image("gifs/langsplat.gif", width: 100%),
      caption: "LangSplatの方が境界がより厳密で精度が高い",
    )
  ],
)

3DGSにCLIPのもつ言語情報を埋め込んでいる。つまり、対応するテキストとガウシアンは、モデル内の表現でで幾何的に同じ場所に配置されるように学習される。
よって、同じオブジェクトに対しては
- クエリテキスト→埋め込み
- シーン画像→埋め込み
という二つの埋め込みのコサイン類似度が大きくなるので、検索ができるという仕組み


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

== 問題設定

LangSplatはそのままでは物体間の位置関係を扱えない。

- LangSplatは名詞だけの処理しかできない

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
- Rel3D #footnote[https://github.com/princeton-vl/Rel3D] (NeurIPS 2020) : 物体ペアの空間関係データセット
- あとは合成データ（シミュレータ）で作る手もあるが、難しそう

「机の上のコップ」は人間には自明だけど、机のすぐ横に台があってその上にあるコップはどうするのか。

VLM がそもそも空間関係をどの程度理解できているのかも未知数。CLIP で「on」ってどのくらいわかってるんだろう。

---

= まとめ

---

== 進捗

- [x] OV-Seg 追試・SAM3 置換評価完了
- [x] 医療・衛星ドメイン調査
- [x] MedDINOv3, SkySense読む
- [x] LangSplat 読む（ざっくり）
- [x] 「3D シーン内の位置関係を含む情報検索」の検討
- [ ] 位置関係を含んだクエリをパースする機構を追加
  - まずは2つのオブジェクトから
- [ ] LERFを読む
- [ ] Rel3Dを読む
- [ ] データセットの模索、検討
- [ ] 位置関係をLangSplatに認識させるor外部にモデル追加
