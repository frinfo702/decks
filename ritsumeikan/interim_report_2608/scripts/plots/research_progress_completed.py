# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib==3.10.5"]
# ///
"""Generate the completed research milestones timeline."""

from datetime import date, datetime

import matplotlib as mpl
import matplotlib.dates as mdates
import matplotlib.pyplot as plt

from _common import (
    BLUE,
    GRID,
    INK,
    RAW,
    add_header,
    configure,
    japanese_month,
    read_csv,
    save,
)


PHASE_LABELS = {
    "OV-Seg reproduction": "OV-Seg 再現",
    "OVSAM3 implementation": "OVSAM3 実装",
    "Research direction exploration": "研究方向の探索",
    "LangSplat environment and reproduction": "LangSplat 環境構築・再現",
    "Evaluation and failure analysis": "評価・失敗分析",
    "Experiment tracking and dataset preparation": "実験追跡・データ準備",
}


def main() -> None:
    configure()
    rows = [
        row
        for row in read_csv(RAW / "research_milestones.csv")
        if row["status"] == "completed"
    ]
    fig, ax = plt.subplots(figsize=(10, 6))
    fig.subplots_adjust(left=0.37, right=0.95, top=0.76, bottom=0.17)
    add_header(fig, "完了した研究工程", "2026年4月〜7月・完了済みの工程のみ")
    display_rows = list(reversed(rows))
    for index, row in enumerate(display_rows):
        row_start = datetime.fromisoformat(row["start_date"])
        row_end = datetime.fromisoformat(row["end_date"])
        ax.barh(
            index,
            (row_end - row_start).days + 1,
            left=mdates.date2num(row_start),
            height=0.58,
            color=BLUE,
            edgecolor=INK,
            linewidth=0.8,
        )
    ax.set_yticks(
        range(len(display_rows)),
        [PHASE_LABELS[row["phase"]] for row in display_rows],
    )
    ax.set_xlim(date(2026, 4, 1), date(2026, 8, 1))
    ax.xaxis.set_major_locator(mdates.MonthLocator())
    ax.xaxis.set_major_formatter(mpl.ticker.FuncFormatter(japanese_month))
    ax.grid(axis="x", color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    ax.spines[["top", "right", "left"]].set_visible(False)
    ax.tick_params(axis="y", length=0, labelsize=11)
    save(fig, "research_progress_completed")


if __name__ == "__main__":
    main()
