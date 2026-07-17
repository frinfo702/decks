#import "@preview/touying:0.6.1": *
#import themes.metropolis: *
#import "@preview/numbly:0.1.0": numbly
#import "@preview/presio:0.1.0": media
#import "@preview/cheq:0.2.2": checklist

#set heading(numbering: numbly("{1}.", default: "1.1"))
#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  config-info(
    title: [個別ゼミ],
    subtitle: [Spatial Relation Search in 3D Scenes],
    author: [Kenichiro Goto],
    date: "2026-07-07",
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
#set page(background: image("images/owl_and_fox.png"))
#title-slide()[]
#set page(background: image("images/presentation_background.png"))


---

= LangSplat の精度問題

---

== 前回の仮説と検証

自分の学習結果と論文の結果の間に大きな乖離がある問題について、以下の仮説を立てていた

#text(weight: "semibold")[推論時の Relevancy Score]

$
  "rel"^l(v; q) = min_i (exp(bold(phi)_"img"^l(v) dot bold(phi)_"qry")) / (exp(bold(phi)_"img"^l(v) dot bold(phi)_"qry") + exp(bold(phi)_"img"^l(v) dot bold(phi)_"canon"^i))
$

canonical phrase（"object", "things", "stuff", "texture"）との相対類似度で正規化。実装上は温度$tau$（デフォルト $tau = 10$）付き softmax で計算される


#text(weight: "semibold")[レベルの選択（Step 4）]

$
  l^* = op("argmax")_(l in {s, p, w}) max_v "smooth"("rel"^l(v; q))
$

各レベルの relevancy map をガウシアンフィルタ（kernel size 20）で平滑化し、最大値を与えるレベルを選択。

#v(0.5em)

その他考えたこと
- 温度 $tau = 10$ の softmax によりスコアが0/1に偏り、小さい領域が不当に高いスコアを出している可能性
- 学習時のハイパーパラメータに問題がある可能性


---

== feature map

#columns(2)[
  #figure(
    image("gif/sofa_original.gif"),
    caption: "original scene images",
  )
  #colbreak()
  #figure(
    image("gif/sofa_feat.gif"),
    caption: "my feature map",
  )
]

CLIP特徴を3DGSに埋め込むことはできていそう

---

== query結果

#columns(2)[
  #figure(
    image("gif/pikachu_query.gif"),
    caption: "query: Pikachu",
  )
  #colbreak()
  #figure(
    image("gif/gamepad_query.gif"),
    caption: "query: gamepad",
  )
]

論文よりだいぶ精度が低く見える

---

#figure(
  image("gif/semantic2.gif"),
)

公式の結果ではセグメンテーションが非常に綺麗にできている。自分の結果とだいぶ違う。

---

== 今後の方針

#text(weight: "bold")[事前学習モデルをダウンロードして評価・デモを回し、自分のチェックポイントと比較する]

- 公式のチェックポイントでの結果と自分の再現結果を直接比較することで、問題の切り分けを行う
- 資料作成段階ではまだ実行できていないが、環境は整っている
- 比較対象:
  - 公式チェックポイントによる評価結果
  - 自分の学習チェックポイントによる評価結果


---

= LangSplat の lint エラー修正

---

== 背景

LangSplat のコードベースには多数の lint エラー（未使用import、型不一致など）が存在し、実行時エラーが出た際のデバッグが煩雑だった。

オリジナルのコードに対して lint エラーを先に潰す PR を作成した。

#link("https://github.com/frinfo702/LangSplat/pull/1")[github.com/frinfo702/LangSplat/pull/1]

- 主な修正内容:
  - 未使用 import の削除
  - 型アノテーションの不一致修正
  - 未使用変数の整理
  - その他フォーマット・スタイルの調整

---

= まとめ

---

== 進捗

- [x] OV-Seg 追試・SAM3 置換評価完了
- [x] 医療・衛星ドメイン調査
- [x] MedDINOv3, SkySense読む
- [x] LangSplat 読む（ざっくり）
- [x] 「3D シーン内の位置関係を含む情報検索」の検討
- [x] LangSplatを動かす
  - 精度が不十分
- [x] LangSplatのlintエラー修正
- [ ] 事前学習モデルでの評価・デモ実行 → 自分のチェックポイントと比較
- [ ] Rel3Dを動かす
- [ ] 位置関係を含んだクエリをパースする機構を追加
  - まずは2つのオブジェクトから
- [ ] LERFを読む
- [ ] データセットの模索、検討
- [ ] 位置関係をLangSplatに認識させるor外部にモデル追加

