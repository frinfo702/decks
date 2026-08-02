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
  paginationPagesDisabled: [1]
---

# 2026年度 中間研究報告

<p lang="ja">3Dシーンにおける位置関係を扱う検索</p>
<p lang="ja">— 総括・今後の計画 —</p>

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
本日の流れ: 研究の問い → 年度ロードマップ → 春学期の結果 → 関係クエリの予備観察
→ 現在進行中の五シーン再現 → 夏期の週次計画 → 活動の振り返り → まとめ。
-->

---
class: content-slide
---

# 研究テーマ

<p lang="ja">"coffee next to the apple" のように、位置関係を含む言語クエリで3Dシーンを検索できるか。</p>

<div class="grid grid-cols-2 gap-6">
  <figure>
    <img src="./assets/source/prior_deck/coffee-next-to-apple.png" alt="coffee next to apple の検索結果">
    <figcaption class="text-xs opacity-60 mt-2">query: coffee next to the apple</figcaption>
  </figure>
  <figure>
    <img src="./assets/source/prior_deck/glass-next-to-apple.png" alt="glass next to apple の検索結果">
    <figcaption class="text-xs opacity-60 mt-2">query: glass next to the apple</figcaption>
  </figure>
</div>

- 現行の relevancy は物体・単語単位の類似度のため、どちらのクエリも赤点が <code>apple</code> へ集まる。
- → 位置関係を「構造」として扱う仕組みが必要。

<!--
現行 LangSplat の relevancy スコアは CLIP 特徴の内積で、物体・単語単位の類似度にすぎません。
関係語をクエリに書き足しても、赤点は参照物体 (apple) へ集中します。
ここから「物体の検索」と「関係の判定」を分離する方向へ問題を定式化しました。
-->

---
class: content-slide
---

# 01 · 年度ロードマップ

<div class="grid grid-cols-2 gap-8 mt-2">
  <img class="w-full h-[360px] object-contain" src="./plots/research_progress_completed.png" alt="完了した研究工程">
  <img class="w-full h-[360px] object-contain" src="./plots/research_plan_remaining.png" alt="今後の研究計画">
</div>

<p class="text-sm opacity-70 text-center">再現・方向探索・基盤整備を経て、夏以降は位置関係モジュールの実装と評価へ進む。</p>


<!--
4–5月: OV-Seg / OVSAM3 の再現。6月: 3D シーン検索へ方向を絞る。7月: LangSplat の
環境構築・再現・失敗解析と、実験追跡 (DagsHub/MLflow) ・データ整備 (LERF-OVS) を完了。
8月の五シーン再現 (進行中) を閉じた後、関係ベースライン → パーサー → 統合 → 評価へ進みます。
-->

---
class: content-slide
---

# 02 · OV-Segの改良

<div class="grid grid-cols-2 gap-8 mt-2">
  <img class="w-full h-[360px] object-contain" src="./plots/ovseg_reproduction_miou.png" alt="OV-Seg再現結果">
  <img class="w-full h-[360px] object-contain" src="./plots/ovsam3_comparison_miou.png" alt="OVSAM3手法置換の比較">
</div>

<p class="text-sm opacity-70 text-center">OVSAM3はR-101構成を上回ったが、SAM3の参考値には届かなかった。</p>

<!--
ADE20K-150 val の mIoU で比較。OV-Seg は Config A (Swin-B / ViT-L14) で 29.58、
Config B (R-101 / ViT-B16) で 24.87 と論文値 (29.6 / 24.8) に一致。
SAM3 マスク + 微調整済み CLIP の OVSAM3 は 25.68 で R-101 構成を上回りましたが、
引用値 39.0 の SAM3 単体には届きませんでした。マスク提案の品質向上は確認できた、と整理できます。
-->

---
class: content-slide
---

# 03 · 位置関係クエリ

<div class="grid grid-cols-2 gap-8 mt-2">
  <figure>
    <img class="w-full h-[340px] object-contain" src="./assets/source/prior_deck/coffee-next-to-apple.png" alt="coffee next to the apple の検索結果">
    <figcaption class="text-sm opacity-60 text-center">coffee next to the apple</figcaption>
  </figure>
  <figure>
    <img class="w-full h-[340px] object-contain" src="./assets/source/prior_deck/glass-next-to-apple.png" alt="glass next to the apple の検索結果">
    <figcaption class="text-sm opacity-60 text-center">glass next to the apple</figcaption>
  </figure>
</div>

<p class="text-sm opacity-70 text-center">関係語を加えても、どちらの検索結果も参照物体のappleへ集中した。</p>

<!--
評価用クエリを直接編集した比較は正当な評価条件になっていないため、ここでは使用しません。
実シーンでは、関係語を含むクエリでもappleの単語類似度が強く、参照物体へ赤点が集まっています。
-->

---
class: content-slide
---

# 04 · RGB 3DGSの学習損失

<img class="w-full h-[330px] object-contain mt-2" src="./plots/dagshub_loss_rgb_3dgs.png" alt="RGB 3DGSのシーン別学習損失">

<p class="text-sm opacity-70 text-center">完了した3シーンを同一軸で比較すると、waldo kitchenの最終損失が最も低い。</p>

<!--
DagsHubから取得した完了済みrunの履歴だけを表示しています。
figurines、ramen、waldo kitchenの観測値を薄線、移動平均を濃線で示しています。
-->

---
class: content-slide
---

# 05 · RGB 3DGSの再構成品質

<img class="w-full h-[330px] object-contain mt-2" src="./plots/dagshub_final_psnr.png" alt="RGB 3DGSの最終PSNR比較">

<p class="text-sm opacity-70 text-center">最終PSNRはwaldo kitchenが32.99 dBで最も高かった。</p>

<!--
完了済みrunのみを比較しています。最終PSNRは figurines 25.43 dB、ramen 30.42 dB、
waldo kitchen 32.99 dB でした。
-->

---
class: content-slide
---

# 06 · Language Gaussian

<img class="w-full h-[330px] object-contain mt-2" src="./plots/dagshub_loss_language_gaussian.png" alt="Language Gaussianのシーン別学習損失">

<p class="text-sm opacity-70 text-center">完了した特徴レベル1を同一軸で比較すると、ramenは学習後半でfigurinesを下回った。</p>

<!--
figurinesとramenの特徴レベル1は30,000ステップまで完了しています。
teatimeは履歴点が1点のみのため、折れ線を作成していません。
-->

---
class: content-slide
---

# 07 · オートエンコーダ

<img class="w-full h-[330px] object-contain mt-2" src="./plots/dagshub_loss_autoencoder.png" alt="オートエンコーダのシーン別学習損失">

<p class="text-sm opacity-70 text-center">完了した2シーンを同一軸で比較すると、ramenは短い学習ステップで低い損失へ到達した。</p>

<!--
未完了のwaldo kitchenは表示していません。
-->

---
class: content-slide
---

# 08 · 夏季休暇の計画

<div class="grid grid-cols-2 gap-8 mt-2">
  <img class="w-full h-[360px] object-contain" src="./plots/summer_plan_august.png" alt="8月開始分の夏期計画">
  <img class="w-full h-[360px] object-contain" src="./plots/summer_plan_september.png" alt="9月開始分の夏期計画">
</div>

<p class="text-sm opacity-70 text-center">再現実験を閉じた後、関係ベースライン、パーサー、統合、評価へ段階的に進む。</p>


<!--
W1: パイプラインのスモークテストと run ID 記録 → W2: Obon 休暇 (斜線、監視のみ)
→ W3: 5シーン完走と checkpoint 比較 → W4: CLIP 空間のずれの切り分け
→ W5: Rel3D ベースライン → W6: クエリパーサー → W7: 統合 → W8: 初回評価 → W9: 結果確定と秋計画の修正。
-->

---
class: content-slide
---

# 09 · 研究実装の活動

<div class="grid grid-cols-2 gap-8 mt-2">
  <img class="w-full h-[370px] object-contain" src="./plots/weekly_activity_ov_seg.png" alt="ov-segの週次コミット数">
  <img class="w-full h-[370px] object-contain" src="./plots/weekly_activity_3dgs_relationship_recognition.png" alt="3dgs-relationship-recognitionの週次コミット数">
</div>

<p class="text-sm opacity-70 text-center">4〜5月のOV-Seg再現から、6〜7月の3DGS・LangSplat実装へ活動が移った。</p>

<!--
GitHub API とローカル git log からリポジトリ別の週次コミット数を集計。
4〜5月は ov-seg（OV-Segの追試・SAM3置換）、6〜7月は 3dgs-relationship-recognition
（LangSplat環境構築・評価・再現パイプライン）へ活動が移っています。
コミット数は活動の補助指標であり、成果量そのものではありません。
-->

---
class: content-slide
---

# 10 · 発表資料の活動

<img class="w-full h-[400px] object-contain mt-2" src="./plots/weekly_activity_decks.png" alt="decksの週次コミット数">

<p class="text-sm opacity-70 text-center">発表資料の更新も週次で記録し、研究実装と報告準備を分けて確認する。</p>

<!--
decksリポジトリの週次コミット数です。研究成果量ではなく、発表準備の補助指標として扱います。
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

春学期の再現を基盤に、夏は「物体検索と関係判定の分離」を最初の実装として評価する。

- 完了: OV-Seg 再現（論文値一致）、OVSAM3 評価、LangSplat 環境構築と公開 checkpoint の再現、DagsHub / MLflow 追跡、LERF-OVS データ整備
- 進行中: 五シーン再現パイプライン
- 夏（8–9月）: Rel3D ベースライン → クエリパーサー → 位置関係モジュールの統合 → 初回評価
- 秋（10月以降）: 関係認識の改善と比較実験を拡張し、論文の根拠を固める

<!--
まず再現を閉じて信頼できるベースラインを作り、その上で関係クエリを
「対象物体 + 関係 + 参照物体」へ分解するパーサーと、空間関係の検証モジュールを実装します。
10月までに安定した関係対応ベースラインを作ることが夏のゴールです。
-->
