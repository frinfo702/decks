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
    date: "2026-06-30",
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

= LangSplatを動かす

---

== feature map

1シーンあたり訓練時間53分

#columns(2)[
  #figure(
    image("gif/sofa_original.gif"),
    caption: "original feature map",
  )
  #colbreak()
  #figure(
    image("gif/sofa_feat.gif"),
    caption: "my feature map",
  )
]

CLIP特徴を3DGSに埋め込むことはできていそう

---

== queryを設定してheatmapを見る

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

自分の結果とだいぶ違うように見える


---

= まとめ

---

== 進捗

- [x] OV-Seg 追試・SAM3 置換評価完了
- [x] 医療・衛星ドメイン調査
- [x] MedDINOv3, SkySense読む
- [x] LangSplat 読む（ざっくり）
- [x] 「3D シーン内の位置関係を含む情報検索」の検討
- [ ] LangSplatを動かす
  - 精度が不十分
- [ ] Rel3Dを読む
- [ ] Rel3Dを動かす
- [ ] LERFを読む
- [ ] 位置関係を含んだクエリをパースする機構を追加
  - まずは2つのオブジェクトから
- [ ] データセットの模索、検討
- [ ] 位置関係をLangSplatに認識させるor外部にモデル追加
