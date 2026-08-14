# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib==3.10.5"]
# ///
"""Generate the remaining research plan timeline."""

from datetime import date, datetime

import matplotlib.dates as mdates
import matplotlib.pyplot as plt

from _common import (
    BLUE_LIGHT,
    GRID,
    INK,
    RAW,
    add_header,
    configure,
    read_csv,
    save,
)


PHASE_LABELS = {
    "Implementation experiments and validation": "実装・実験・検証",
    "Thesis writing": "論文執筆",
}

PHASE_END_DATES = {
    "Implementation experiments and validation": "2026-11-15",
}


def main() -> None:
    configure()
    rows = [
        row
        for row in read_csv(RAW / "research_milestones.csv")
        if row["status"] == "proposed"
    ]
    fig, ax = plt.subplots(figsize=(10, 6))
    fig.subplots_adjust(left=0.37, right=0.95, top=0.76, bottom=0.17)
    add_header(fig, "今後の研究計画", "2026年8月1日〜12月31日")
    display_rows = list(reversed(rows))
    for index, row in enumerate(display_rows):
        row_start = datetime.fromisoformat(row["start_date"])
        row_end = datetime.fromisoformat(
            PHASE_END_DATES.get(row["phase"], row["end_date"])
        )
        ax.barh(
            index,
            (row_end - row_start).days + 1,
            left=mdates.date2num(row_start),
            height=0.58,
            color=BLUE_LIGHT,
            edgecolor=INK,
            linewidth=0.8,
        )
    ax.set_yticks(
        range(len(display_rows)),
        [PHASE_LABELS[row["phase"]] for row in display_rows],
    )
    ax.set_xlim(date(2026, 8, 1), date(2026, 12, 31))
    ticks = [
        date(2026, 8, 1),
        date(2026, 9, 1),
        date(2026, 10, 1),
        date(2026, 11, 1),
        date(2026, 11, 15),
        date(2026, 12, 1),
        date(2026, 12, 31),
    ]
    ax.set_xticks(
        ticks,
        ["8/1", "9/1", "10/1", "11/1", "11/15", "12/1", "12/31"],
    )
    ax.grid(axis="x", color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    ax.spines[["top", "right", "left"]].set_visible(False)
    ax.tick_params(axis="y", length=0, labelsize=11)
    save(fig, "research_plan_remaining")


if __name__ == "__main__":
    main()
