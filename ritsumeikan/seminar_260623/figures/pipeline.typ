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
  MLP --> SC[\"score\"]",
  ),
  caption: [パイプライン全体],
)
