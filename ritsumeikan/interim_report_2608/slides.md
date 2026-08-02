---
theme: academic
title: 2026年度 中間研究報告
info: |
  Ritsumeikan University · individual research progress · 2026-08-02
  FY2026 interim report: reproduction of open-vocabulary segmentation and LangSplat, direction exploration toward spatial-relation-aware retrieval in 3D scenes, and the summer implementation plan.
layout: cover
hideInToc: true
transition: fade
coverAuthor: Kenichiro Goto
coverAuthorUrl: https://github.com/frinfo702
coverDate: 2026-08-03
themeConfig:
  paginationPagesDisabled: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
---

# 2026年度 中間研究報告

3Dシーンにおける位置関係を扱う検索
— 総括・今後の計画 —

<!--
4月から7月の研究活動を中間報告としてまとめます。
2D 開語彙セグメンテーションの再現から始め、LangSplat による3D シーン検索の再現と
位置関係クエリの失敗解析を経て、夏に「物体検索と関係判定の分離」を実装する計画です。
-->

---
layout: table-of-contents
---

# Table of Contents

<!--
本日の流れ: 研究の問い → 年度ロードマップ → 春学期の結果 → LangSplat の原理
→ 追試と評価 → 位置関係クエリの限界 → LangSplat + Rel3D → 夏期計画 → まとめ。
-->

---
layout: two-cols-header
class: content-slide
---

# 研究テーマ

"coffee next to the apple" のように、位置関係を含む言語クエリで3Dシーンを検索する

::left::

<img class="w-full h-[260px] object-contain" src="./assets/source/prior_deck/coffee-next-to-apple.png" alt="coffee next to apple の検索結果">

*query: coffee next to the apple*

::right::

<img class="w-full h-[260px] object-contain" src="./assets/source/prior_deck/glass-next-to-apple.png" alt="glass next to apple の検索結果">

*query: glass next to the apple*

::bottom::

- 現行の relevancy は物体・単語単位の類似度のため、どちらのクエリも赤点が `apple` へ集まる。
- → 位置関係を「構造」として扱う仕組みが必要。

<!--
現行 LangSplat の relevancy スコアは CLIP 特徴の内積で、物体・単語単位の類似度にすぎません。
関係語をクエリに書き足しても、赤点は参照物体 (apple) へ集中します。
ここから「物体の検索」と「関係の判定」を分離する方向へ問題を定式化しました。
-->

---
layout: two-cols-header
class: content-slide
---

# 年度ロードマップ

::left::

<img class="w-full h-[360px] object-contain" src="./plots/research_progress_completed.png" alt="完了した研究工程">

::right::

<img class="w-full h-[360px] object-contain" src="./plots/research_plan_remaining.png" alt="今後の研究計画">

::bottom::

8月1日から実装・実験・検証を続け、11月1日から12月31日まで論文を執筆する。

<!--
4–5月: OV-Seg / OVSAM3 の再現。6月: 3D シーン検索へ方向を絞る。7月: LangSplat の
環境構築・再現・失敗解析と、実験追跡 (DagsHub/MLflow) ・データ整備 (LERF-OVS) を完了。
8月1日から10月31日までは、五シーン再現を閉じた後、関係ベースライン → パーサー → 統合 → 評価へ進みます。
11月1日から12月31日までは論文執筆に取り組みます。
-->

---
layout: two-cols-header
class: content-slide
---

# OV-Segの改良


::left::

<img class="w-full h-[340px] object-contain" src="./plots/ovseg_reproduction_miou.png" alt="OV-Seg再現結果">

::right::

<img class="w-full h-[340px] object-contain" src="./plots/ovsam3_comparison_miou.png" alt="OVSAM3手法置換の比較">

::bottom::

[OV-Seg](https://jeff-liangf.github.io/projects/ovseg/)はオープンボキャブラリーのセグメンテーションをするモデル。
その中のデータ前処理であるMask生成部分をSAM3に変更し性能改善するかを検証した

OVSAM3はR-101構成を若干上回ったが、ピュアなSAM3にすら届かなかった。

<!--
ADE20K-150 val の mIoU で比較。OV-Seg は Config A (Swin-B / ViT-L14) で 29.58、
Config B (R-101 / ViT-B16) で 24.87 と論文値 (29.6 / 24.8) に一致。
SAM3 マスク + 微調整済み CLIP の OVSAM3 は 25.68 で R-101 構成を上回りましたが、
引用値 39.0 の SAM3 単体には届きませんでした。マスク提案の品質向上は確認できた、と整理できます。

[Sources]
- data/raw/evaluation_metrics.csv
-->

---
class: content-slide
---

# LangSplat

3D Gaussian Splattingの各Gaussianに、CLIP由来の言語特徴を追加する。

<img class="w-full h-[270px] object-contain mt-1" src="./assets/source/papers/langsplat-figure-2.png" alt="LangSplat論文Figure 2の処理全体">

| 境界を作る | 3次元へ蒸留する | 文章で検索する |
|---|---|---|
| SAMのwhole / part / subpartマスクで画素ごとの意味を限定 | 同じ物体を複数視点で観測し、Gaussianへ言語特徴を学習 | レンダリングした特徴をCLIP空間へ戻し、テキストとの類似度を計算 |

*LangSplat, Figure 2（CVPR 2024）*

<!--
LangSplat の中心は、見た目を表すRGB Gaussianとは別に、各Gaussianへ言語特徴を持たせることです。
SAMで得た輪郭の明確な領域をCLIPで符号化し、その特徴を複数視点から3Dへ蒸留します。
問い合わせ時は、任意視点へ言語特徴を高速にレンダリングし、テキストとの類似度で対象を探します。

[Sources]
- Qin et al., "LangSplat: 3D Language Gaussian Splatting," CVPR 2024, Figure 2. https://openaccess.thecvf.com/content/CVPR2024/papers/Qin_LangSplat_3D_Language_Gaussian_Splatting_CVPR_2024_paper.pdf
-->


---
class: content-slide
---

# 公開checkpointを使った追試

| apple | coffee | bag of cookies |
|:---:|:---:|:---:|
| <img class="w-full h-[215px] object-cover" src="./assets/source/prior_deck/apple.png" alt="appleのlocalization結果"> | <img class="w-full h-[215px] object-cover" src="./assets/source/prior_deck/coffee.png" alt="coffeeのlocalization結果"> | <img class="w-full h-[215px] object-cover" src="./assets/source/prior_deck/bag-of-cookies.png" alt="bag of cookiesのlocalization結果"> |

**LERF-OVS · teatime（mask threshold = 0.4）**

| mIoU | Localization Accuracy | 論文との比較 |
|:---:|:---:|---|
| **0.6503** | **0.8814** | teatimeの報告値65.1%、88.1%とほぼ一致 |

赤点がGT bbox内に入る例を確認した。

<!--
公開checkpointで単体物体のlocalizationが成立するかを先に確認しました。
赤点は平滑化したrelevancy mapのargmax、黒の点線枠はGTです。
teatimeのmIoU 0.6503、Localization Accuracy 0.8814は論文表の65.1%、88.1%とほぼ一致します。

[Sources]
- Qin et al., "LangSplat: 3D Language Gaussian Splatting," CVPR 2024, Tables 1-2. https://openaccess.thecvf.com/content/CVPR2024/papers/Qin_LangSplat_3D_Language_Gaussian_Splatting_CVPR_2024_paper.pdf
- data/raw/evaluation_metrics.csv
- ritsumeikan/seminar_260714/goto_mini_seminar.typ
-->

---
layout: two-cols-header
class: content-slide
---

# 位置関係クエリ

::left::

<img class="w-full h-[280px] object-contain" src="./assets/source/prior_deck/coffee-next-to-apple.png" alt="coffee next to the apple の検索結果">

*coffee next to the apple*

::right::

<img class="w-full h-[280px] object-contain" src="./assets/source/prior_deck/glass-next-to-apple.png" alt="glass next to the apple の検索結果">

*glass next to the apple*

::bottom::

$$
\text{relevancy}(q)=\min_i\frac{\exp(\phi_{img}\!\cdot\!\phi_{qry})}
{\exp(\phi_{img}\!\cdot\!\phi_{qry})+\exp(\phi_{img}\!\cdot\!\phi^{i}_{canon})}
$$

単一の画像特徴と文章全体の類似度なので、subject・relation・anchorの構造を区別できない。

<!--
実シーンでは、関係語を含むクエリでもappleの単語類似度が強く、参照物体へ赤点が集まりました。
この式は各画素のCLIP画像特徴とクエリ文章の内積を計算するだけで、2物体の座標や関係を入力に取りません。
なお、評価用annotationを2件だけ書き換えた予備観察なので、定量比較ではなく失敗の仕組みを示す例として扱います。

[Sources]
- Qin et al., "LangSplat: 3D Language Gaussian Splatting," CVPR 2024, Sec. 3.4. https://openaccess.thecvf.com/content/CVPR2024/papers/Qin_LangSplat_3D_Language_Gaussian_Splatting_CVPR_2024_paper.pdf
- ritsumeikan/seminar_260714/goto_mini_seminar.typ
-->

---
class: content-slide
---

# 事前学習から追試

1. データ前処理。複数視点画像からCOLMAPによるカメラ姿勢・疎点群推定
2. SAMによるsubpart／part／wholeマスク生成と、OpenCLIPによる512次元領域特徴抽出
3. RGB-3DGSの学習。2次元画像をレンダリングして再構成品質を損失とする
4. シーン固有Autoencoderの学習. $f \in \mathbb{R}^{512} \xrightarrow{E} z \in \mathbb{R}^{3}\xrightarrow{D} \hat{f} \in \mathbb{R}^{512}$と元CLIP特徴を再構成
5. 2で得た全CLIP画像特徴を3次元latentへ圧縮しRGB-3DGSを固定し、粒度別Language Gaussianを学習
6. 粒度別3次元特徴をレンダリングし、512次元CLIP空間へ復元
7. テキストqueryとのrelevance mapを計算し、最適粒度を選択
8. Localization Accuracy／IoU／mIoUで評価

---
layout: two-cols-header
class: content-slide
---

# metrics

::left::

<img class="w-full h-[310px] object-contain" src="./plots/dagshub_loss_rgb_3dgs.png" alt="RGB 3DGSのシーン別学習損失">

*RGB 3DGS · training loss*

::right::

<img class="w-full h-[310px] object-contain" src="./plots/dagshub_final_psnr.png" alt="RGB 3DGSの最終PSNR比較">

*RGB 3DGS · final PSNR*

::bottom::

完了3シーンでは、waldo kitchenが最小の最終lossと最大PSNR 32.99 dBを示した。

<!--
DagsHubから取得した完了済みrunのみを比較しています。
RGB 3DGSのlossは観測値を薄線、移動平均を濃線で表示しています。
最終PSNRはfigurines 25.43 dB、ramen 30.42 dB、waldo kitchen 32.99 dBです。

[Sources]
- data/processed/dagshub_canonical_runs.csv
- data/raw/dagshub_metric_history.csv
-->

---
layout: two-cols-header
class: content-slide
---



::left::

<img class="w-full h-[310px] object-contain" src="./plots/dagshub_loss_autoencoder.png" alt="オートエンコーダのシーン別学習損失">


::right::

<img class="w-full h-[310px] object-contain" src="./plots/dagshub_loss_language_gaussian.png" alt="Language Gaussianのシーン別学習損失">


::bottom::

圧縮器と3D言語特徴の両段階でlossが低下し、学習パイプラインが動作することを確認した。

<!--
Autoencoderは完了済みのfigurinesとramenを比較し、未完了のwaldo kitchenは除外しています。
Language Gaussianは完了した特徴レベル1を比較しています。teatimeは履歴点が1点のみのため折れ線に含めていません。

[Sources]
- data/processed/dagshub_canonical_runs.csv
- data/raw/dagshub_metric_history.csv
-->


---
class: content-slide
---

# LangSplat + Rel3D

**物体検索と関係判定を分離し、候補ペアをRel3Dで再順位付けする。**

> **Query parse** → **LangSplat × 2** → **Geometry** → **Rel3D MLP** → **Render**

| Parse | Retrieve | Classify |
|---|---|---|
| `q = (coffee, next to, apple)` | subjectとanchorを別々に検索 | candidate pair → relation probability |

$$
p(r\mid s,a)=\operatorname{softmax}\!\left(g_\theta([\mathbf f_s,\mathbf f_a])\right)
$$

LangSplatは「どこに何があるか」、Rel3Dは「2物体がどの関係にあるか」を担当する。

<!--
入力をsubject、relation、anchorへ分解します。subjectとanchorをLangSplatで別々に検索し、候補Gaussian群から幾何特徴を作ります。
Rel3DのMLPは候補ペアの関係確率を出し、クエリと一致するペアだけを残します。
この分離により、LangSplat自体をend-to-endで再学習せずに、関係判定を追加できます。

[Sources]
- Goyal et al., "Rel3D: A Minimally Contrastive Benchmark for Grounding Spatial Relations in 3D," NeurIPS 2020. https://papers.nips.cc/paper/2020/file/76dc611d6ebaafc66cc0879c71b5db5c-Paper.pdf
- Qin et al., "LangSplat: 3D Language Gaussian Splatting," CVPR 2024. https://openaccess.thecvf.com/content/CVPR2024/papers/Qin_LangSplat_3D_Language_Gaussian_Splatting_CVPR_2024_paper.pdf
-->

---
class: content-slide
---

# Rel3Dへ渡す18次元特徴

<img class="w-full h-[150px] object-cover object-top mt-1" src="./assets/source/papers/rel3d-mlp-examples.png" alt="Rel3D MLPの成功例と失敗例">

*Rel3D, Figure 6: aligned featureで学習したMLPの成功例と失敗例*

各物体を中心・回転・大きさの9次元で表し、subjectとanchorを連結する。

$$
\mathbf f_{obj}=(x,y,z,\alpha,\beta,\gamma,w,h,d)\in\mathbb R^9,
\qquad
\mathbf x=[\mathbf f_{subject},\mathbf f_{anchor}]\in\mathbb R^{18}
$$

| LangSplat側 | Adapter側 |
|---|---|
| relevancy上位Gaussianをクラスタ化し、重心・bbox寸法・姿勢を推定 | 座標系をそろえて18次元化する。中心の差を取った相対ベクトル $\in \mathbb{R}^3$だけでは入力形式として不十分 |

<!--
Rel3Dのaligned featureは、各物体を9次元で表し、2物体を連結した18次元を5層MLPへ入力します。
過去資料ではLangSplatの座標差と同じ形式と整理していましたが、厳密には異なります。
LangSplat側のGaussian群から中心・大きさ・姿勢を推定し、Rel3Dと同じ座標系へ変換するadapterが実装上の中心課題です。

[Sources]
- Goyal et al., "Rel3D: A Minimally Contrastive Benchmark for Grounding Spatial Relations in 3D," NeurIPS 2020, Sec. 5 and Figure 6. https://papers.nips.cc/paper/2020/file/76dc611d6ebaafc66cc0879c71b5db5c-Paper.pdf
-->

---
layout: two-cols-header
class: content-slide
---

# 夏季休暇の計画

::left::

<img class="w-full h-[350px] object-contain" src="./plots/summer_plan_august.png" alt="8月開始分の夏期計画">

::right::

<img class="w-full h-[350px] object-contain" src="./plots/summer_plan_september.png" alt="9月開始分の夏期計画">

::bottom::

再現実験を閉じた後、18次元adapter、Rel3D、クエリパーサー、統合評価へ進む。

<!--
W1: パイプラインのスモークテストとrun ID記録 → W2: Obon休暇 → W3: 5シーン完走とcheckpoint比較
→ W4: CLIP空間のずれの切り分け → W5: Rel3D基準手法と18次元adapter
→ W6: クエリパーサー → W7: 統合 → W8: 初回評価 → W9: 結果確定と秋計画の修正。

[Sources]
- data/raw/summer_plan.csv
-->

---
layout: index
indexEntries:
  - { title: "ov-seg — OV-Seg reproduction and SAM3 replacement", uri: "https://github.com/frinfo702/ov-seg" }
  - { title: "3dgs-relationship-recognition — LangSplat reproduction and relation pipeline", uri: "https://github.com/frinfo702/3dgs-relationship-recognition" }
  - { title: "LERF-OVS dataset (Hugging Face)", uri: "https://huggingface.co/datasets/frinfo702-hf/LERF-OVS" }
  - { title: "decks — this presentation and seminar materials", uri: "https://github.com/frinfo702/decks" }
indexRedirectType: external
---

# まとめ

LangSplatの再現を基盤に、「物体検索」と「関係判定」を分離した構成を評価する。

- 完了: OV-Seg 再現（論文値一致）、OVSAM3 評価、LangSplat 環境構築と公開 checkpoint の再現、DagsHub / MLflow 追跡、LERF-OVS データ整備
- 進行中: 五シーン再現パイプライン
- 8月1日〜10月31日: 18次元adapter → Rel3D ベースライン → クエリパーサー → 統合 → 実験・検証
- 11月1日〜12月31日: 論文執筆・修正

<!--
まずLangSplatの再現を閉じ、単体物体のlocalizationを信頼できる基準にします。
次に関係クエリを三つ組へ分解し、LangSplatの候補Gaussian群をRel3Dの18次元入力へ変換します。
10月31日までに実装・実験・検証を進め、11月1日から論文執筆へ移ります。
-->
