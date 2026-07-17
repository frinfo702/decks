---
theme: default
title: Spatial Relation Search in 3D Scenes
info: |
  Ritsumeikan individual seminar, 2026-07-14.
  Experiment tracking, LangSplat checkpoint evaluation, and spatial-relation queries.
layout: cover
class: cover-slide
transition: fade
drawings:
  persist: false
---

<img class="cover-art" src="./assets/cover.png" alt="Owl and fox illustration">

<div class="cover-copy">
  <p class="eyebrow">INDIVIDUAL SEMINAR · 2026.07.14</p>
  <h1>Spatial Relation Search<br><span>in 3D Scenes</span></h1>
  <p class="cover-subtitle" lang="ja">LangSplat の再評価から、位置関係を扱う検索機構へ</p>
  <div class="cover-meta"><span>Kenichiro Goto</span><span>Ritsumeikan University</span></div>
</div>

<!--
今週は、まず評価が崩れていた理由を切り分け、公開 checkpoint を基準に再評価しました。
そのうえで、単体物体の検索から位置関係を含む検索へ進んだ結果を共有します。
-->

---
class: content-slide
---

<p class="eyebrow">THIS WEEK</p>

# Three findings changed the direction

<p class="lead" lang="ja">「学習の不備」と「手法そのものの限界」を分けて考えられる状態になりました。</p>

<div class="thesis-grid">
  <section class="panel" v-click>
    <span class="step-no">01 · REPRODUCE</span>
    <h2>実験を残す</h2>
    <p>DagsHub / MLflow を追加し、run・指標・画像・checkpoint を一箇所で比較できる準備を行いました。</p>
  </section>
  <section class="panel" v-click>
    <span class="step-no">02 · DIAGNOSE</span>
    <h2>公開 checkpoint で再評価</h2>
    <p>単体オブジェクトの localization は論文値に近く、自前学習側に問題がある可能性を絞り込みました。</p>
  </section>
  <section class="panel" v-click>
    <span class="step-no">03 · EXTEND</span>
    <h2>位置関係クエリを試す</h2>
    <p><code>next to</code> を含む検索は失敗しました。物体類似度だけでは関係を構造的に扱えません。</p>
  </section>
</div>

<p v-after class="takeaway">結論：まず個々の物体を見つけ、その後に関係を検証する構成が必要です。</p>

---
class: content-slide
---

<p class="eyebrow">01 · EXPERIMENT OPERATIONS</p>

# Make every run comparable

<p class="lead" lang="ja">画像を手元で見比べる運用から、追跡可能な実験管理へ移行します。</p>

<div class="tracking-grid">
  <section class="panel">
    <span class="step-no">PARAMETERS</span>
    <h2>条件</h2>
    <p>dataset、scene、feature level、学習率など、再現に必要な設定を run ごとに保存します。</p>
  </section>
  <section class="panel">
    <span class="step-no">OBSERVATIONS</span>
    <h2>指標と画像</h2>
    <p>loss、mIoU、Localization Accuracy、レンダリング画像を同じ画面で比較します。</p>
  </section>
  <section class="panel">
    <span class="step-no">ARTIFACTS</span>
    <h2>成果物</h2>
    <p>最終 checkpoint と評価結果を DagsHub 上の MLflow に紐づけます。</p>
  </section>
</div>

<div class="status-line"><span class="status-dot"></span><span>実装は PR #4。接続は完了し、実運用での比較検証は次の段階です。</span></div>

<p class="caption"><a href="https://github.com/frinfo702/3dgs-relationship-recognition/pull/4">github.com/frinfo702/3dgs-relationship-recognition/pull/4</a></p>

---
class: content-slide
---

<p class="eyebrow">02 · DIAGNOSIS</p>

# It looked plausible—but learned the wrong space

<div class="media-grid">
  <figure class="media-card">
    <img src="./assets/sofa-original.gif" alt="Original sofa scene">
    <figcaption class="media-label"><span>Original scene</span><span>RGB</span></figcaption>
  </figure>
  <figure class="media-card">
    <img src="./assets/sofa-feature.gif" alt="Learned feature map">
    <figcaption class="media-label"><span>Our learned feature map</span><span>FEATURE</span></figcaption>
  </figure>
</div>

<div class="diagnosis-line">
  <b>ROOT CAUSE</b>
  <span lang="ja">feature map は生成できていましたが、埋め込まれた 3D 言語特徴が CLIP 空間からずれていました。</span>
</div>

<!--
見た目だけでは学習の正否を判断できませんでした。
GT と比較して各類似度の値を確認すると、公開 checkpoint と大きく異なっていました。
-->

---
class: content-slide
---

<p class="eyebrow">02 · RELEVANCY SCORE</p>

# The threshold has a geometric meaning

<div class="formula-grid">
  <section class="formula-box">

$$
\operatorname{rel}^{l}(v;q)=
\min_i
\frac{e^{\phi^{l}_{\mathrm{img}}(v)\cdot\phi_{\mathrm{qry}}}}
{e^{\phi^{l}_{\mathrm{img}}(v)\cdot\phi_{\mathrm{qry}}}
+e^{\phi^{l}_{\mathrm{img}}(v)\cdot\phi^{i}_{\mathrm{canon}}}}
$$

<p class="caption" lang="ja"><code>v</code>: pixel · <code>q</code>: query · <code>φ</code>: CLIP embedding</p>
  </section>
  <section class="formula-aside panel">
    <img src="./assets/relevancy-derivation.jpg" alt="Derivation of the relevancy threshold">
    <p class="caption" lang="ja">relevancy の変形と閾値 <code>0.5</code> の意味</p>
  </section>
</div>

<p class="takeaway" lang="ja"><code>relevancy &lt; 0.5</code> を 0 とする処理の見落としも、元実装との差を生んでいました。</p>

---
class: content-slide
---

<p class="eyebrow">02 · PUBLIC CHECKPOINT</p>

# Define success before reading the heatmap

<p class="lead" lang="ja">公開 checkpoint を使い、論文デモと同じ localization 判定を再現しました。</p>

<div class="legend-grid">
  <section class="legend-item">
    <div class="legend-symbol">┄</div>
    <h2>Ground truth</h2>
    <p lang="ja">黒の点線枠。LERF の annotation JSON から取得した対象領域です。</p>
  </section>
  <section class="legend-item">
    <div class="legend-symbol" style="color:#ff4d5e">●</div>
    <h2>Prediction</h2>
    <p lang="ja">赤い点。平滑化した relevancy map の <code>argmax</code> です。</p>
  </section>
  <section class="legend-item">
    <div class="legend-symbol">◐</div>
    <h2>Relevancy</h2>
    <p lang="ja">カラフルな heatmap。<code>&lt; 0.5</code> の領域は RGB を暗く表示します。</p>
  </section>
</div>

<p class="takeaway" lang="ja">赤い点がいずれかの GT bbox 内に入れば <code>hit</code> と判定します。</p>

---
class: content-slide
---

<p class="eyebrow">02 · SUCCESS CASES</p>

# Public weights recover object localization

<div class="success-grid">
  <figure class="media-card">
    <img src="./assets/apple.png" alt="Apple localization result">
    <figcaption><span class="query-badge">query: apple</span></figcaption>
  </figure>
  <figure class="media-card">
    <img src="./assets/coffee.png" alt="Coffee localization result">
    <figcaption><span class="query-badge">query: coffee</span></figcaption>
  </figure>
  <figure class="media-card">
    <img src="./assets/bag-of-cookies.png" alt="Bag of cookies localization result">
    <figcaption><span class="query-badge">query: bag of cookies</span></figcaption>
  </figure>
</div>

<p class="takeaway" lang="ja">赤点は GT 枠内に入り、heatmap も対象オブジェクトへ集中しています。</p>

---
class: content-slide
---

<p class="eyebrow">02 · EVIDENCE &amp; LIMIT</p>

# The benchmark matches—even with visible failures

<div class="evidence-grid">
  <section>
    <img class="hero-image" src="./assets/bear-nose.png" alt="Failure case for bear nose query">
    <p class="caption"><code>query: bear nose</code> — heatmap はクマ全体へ広がり、赤点は GT 枠外です。</p>
  </section>
  <section class="metrics-stack">
    <div class="metric"><span>teatime · mIoU</span><strong>0.6503</strong></div>
    <div class="metric"><span>Localization Acc.</span><strong>0.8814</strong></div>
    <img class="paper-thumb" src="./assets/langsplat-paper-tables.png" alt="LangSplat paper benchmark tables">
  </section>
</div>

<p class="takeaway" lang="ja">全例が成功するわけではありませんが、teatime の集計値は論文報告とほぼ一致しました。</p>

---
class: content-slide
---

<p class="eyebrow">02 · LOCALIZATION PIPELINE</p>

# Compare → smooth → select → locate

<div class="pipeline">
  <section class="pipeline-step" v-click><span>01</span><h2>Compare</h2><p>level ごとに query との relevancy map を作ります。</p></section>
  <section class="pipeline-step" v-click><span>02</span><h2>Smooth</h2><p><code>30 × 30</code> の平均フィルタで局所ノイズを抑えます。</p></section>
  <section class="pipeline-step" v-click><span>03</span><h2>Select</h2><p>ピークが最大の SAM / feature level を選びます。</p></section>
  <section class="pipeline-step" v-click><span>04</span><h2>Locate</h2><p>選択した map の最大位置を赤い点として描画します。</p></section>
</div>

```python {all|2|3|4|5}
maps = [relevancy(features[level], query) for level in levels]
smooth = [mean_filter(m, size=30) for m in maps]
chosen = max(range(len(levels)), key=lambda i: smooth[i].max())
coord = argmax_2d(smooth[chosen])
draw_prediction(coord)
```

<p class="takeaway" lang="ja">公開 checkpoint で localization が通るため、これまでの主因は自前学習側にあると考えられます。</p>

---
class: content-slide
---

<p class="eyebrow">03 · RELATION QUERIES</p>

# “Next to” collapses back to object similarity

<div class="relation-grid">
  <figure class="media-card">
    <img src="./assets/coffee-next-to-apple.png" alt="Coffee next to apple query result">
    <figcaption><span class="query-badge">coffee next to the apple</span></figcaption>
  </figure>
  <figure class="media-card">
    <img src="./assets/glass-next-to-apple.png" alt="Glass next to apple query result">
    <figcaption><span class="query-badge">glass next to the apple</span></figcaption>
  </figure>
</div>

<div class="warning-strip" lang="ja">どちらも赤点は apple へ集まりました。表示中の bbox は元 annotation の GT で、関係クエリ用の正解枠ではありません。</div>

<p class="takeaway" lang="ja">現行 relevancy は単語・物体単位の類似度であり、関係語を構造として評価していません。</p>

---
class: content-slide
---

<p class="eyebrow">03 · METRIC SHIFT</p>

# Two relation queries expose the gap

<p class="lead" lang="ja">評価対象が少ないため参考値ですが、関係クエリの追加で両指標が明確に低下しました。</p>

<div class="compare-grid">
  <section class="score-card">
    <span class="step-no">BASELINE · TEATIME</span>
    <h2>Object queries</h2>
    <div class="score-row">
      <div><span>mIoU</span><strong>0.6503</strong></div>
      <div><span>Localization</span><strong>0.8814</strong></div>
    </div>
  </section>
  <section class="score-card experiment">
    <span class="step-no">EXPERIMENT · + RELATIONS</span>
    <h2>Relation queries included</h2>
    <div class="score-row">
      <div><span>mIoU</span><strong>0.5733</strong></div>
      <div><span>Localization</span><strong>0.7458</strong></div>
    </div>
  </section>
</div>

<p class="takeaway">Δ mIoU = −0.0770 · Δ Localization Accuracy = −0.1356</p>

---
class: content-slide
---

<p class="eyebrow">03 · PROPOSED DIRECTION</p>

# Separate object retrieval from relation reasoning

<p class="lead" lang="ja">一つの長い埋め込みで解くのではなく、クエリを分解して段階的に検証します。</p>

<div class="architecture">
  <section class="panel">
    <span class="step-no">PARSE</span>
    <h2>構造へ分解</h2>
    <div class="token-line"><span>coffee</span><span>next to</span><span>apple</span></div>
  </section>
  <div class="arrow">→</div>
  <section class="panel">
    <span class="step-no">LOCALIZE</span>
    <h2>物体を個別に探索</h2>
    <p>subject と reference object の候補位置をそれぞれ取得します。</p>
  </section>
  <div class="arrow">→</div>
  <section class="panel">
    <span class="step-no">VERIFY</span>
    <h2>3D 関係を検証</h2>
    <p>距離・方向・接触などの制約を候補ペアへ適用します。</p>
  </section>
</div>

<p class="takeaway">Object similarity ≠ relation reasoning.</p>

---
class: content-slide
---

<p class="eyebrow">NEXT EXPERIMENT</p>

# Start with two objects and one relation

<div class="next-grid">
  <section class="next-list">
    <div class="next-item"><b>01</b><div><h2>Parse</h2><p>クエリを「対象物体 + 関係 + 参照物体」に分解します。</p></div></div>
    <div class="next-item"><b>02</b><div><h2>Localize</h2><p>二つの物体を独立に localization し、候補集合を作ります。</p></div></div>
    <div class="next-item"><b>03</b><div><h2>Verify</h2><p>Rel3D を動かし、単純な空間関係から評価します。</p></div></div>
  </section>
  <section class="panel">
    <span class="step-no">CURRENT CONCLUSION</span>
    <h2>What we know now</h2>
    <p>公開 checkpoint では単体オブジェクトの localization を再現できました。</p>
    <p>一方、位置関係クエリは現行の relevancy だけでは扱えません。</p>
    <p class="takeaway" lang="ja">次は「物体の検索」と「関係の判定」を分離して検証します。</p>
  </section>
</div>

---
class: content-slide
---

<p class="eyebrow">PROJECT STATUS</p>

# Progress and remaining work

<div class="status-list">
  <div class="status-item done">OV-Seg 追試・SAM3 置換評価</div>
  <div class="status-item done">医療・衛星ドメイン調査</div>
  <div class="status-item done">MedDINOv3 / SkySense 調査</div>
  <div class="status-item done">LangSplat の調査・実行</div>
  <div class="status-item done">lint エラー修正</div>
  <div class="status-item done">DagsHub / MLflow 追加（PR #4）</div>
  <div class="status-item done">公開 checkpoint の評価・デモ</div>
  <div class="status-item done">位置関係クエリの試行</div>
  <div class="status-item todo">Rel3D の実行</div>
  <div class="status-item todo">関係クエリ parser の追加</div>
  <div class="status-item todo">自前学習と公開 ckpt の差分切り分け</div>
  <div class="status-item todo">LERF・データセットの追加調査</div>
</div>

<p class="takeaway">Next: parse → localize → verify.</p>
