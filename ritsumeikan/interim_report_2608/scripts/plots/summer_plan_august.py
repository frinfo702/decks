# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib==3.10.5"]
# ///
"""Generate the August-start portion of the summer plan."""

from datetime import date, datetime

import matplotlib as mpl
import matplotlib.dates as mdates
import matplotlib.pyplot as plt

from _common import (
    BLUE,
    BLUE_LIGHT,
    GOLD,
    GOLD_LIGHT,
    GRID,
    INK,
    MUTED,
    OLIVE,
    PINK,
    RAW,
    add_header,
    configure,
    japanese_month_day,
    read_csv,
    save,
)


SUMMER_LABELS = {
    "1": "パイプライン動作確認・実行ID記録",
    "2": "お盆休暇・監視のみ",
    "3": "5シーン実行・チェックポイント比較",
    "4": "CLIP空間の不一致を診断",
    "5": "Rel3D基準手法・接続確認",
}
WORKSTREAM_COLORS = {
    "reproduction": BLUE,
    "break": MUTED,
    "diagnosis": GOLD,
    "relation_baseline": OLIVE,
    "query_parser": PINK,
    "integration": BLUE_LIGHT,
    "evaluation": GOLD_LIGHT,
    "reporting": "#AEB5BD",
}


def main() -> None:
    configure()
    rows = [row for row in read_csv(RAW / "summer_plan.csv") if int(row["week"]) <= 5]
    fig, ax = plt.subplots(figsize=(10, 5.8))
    fig.subplots_adjust(left=0.43, right=0.95, top=0.72, bottom=0.18)
    add_header(fig, "8月")
    display_rows = list(reversed(rows))
    for index, row in enumerate(display_rows):
        row_start = datetime.fromisoformat(row["start_date"])
        row_end = datetime.fromisoformat(row["end_date"])
        ax.barh(
            index,
            (row_end - row_start).days + 1,
            left=mdates.date2num(row_start),
            height=0.6,
            color=WORKSTREAM_COLORS[row["workstream"]],
            edgecolor=INK,
            linewidth=0.8,
            hatch="///" if row["workstream"] == "break" else None,
        )
    ax.set_yticks(
        range(len(display_rows)),
        [SUMMER_LABELS[row["week"]] for row in display_rows],
    )
    ax.set_xlim(date(2026, 8, 1), date(2026, 9, 7))
    ax.xaxis.set_major_locator(mdates.WeekdayLocator(byweekday=mdates.MO))
    ax.xaxis.set_major_formatter(mpl.ticker.FuncFormatter(japanese_month_day))
    ax.grid(axis="x", color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    ax.spines[["top", "right", "left"]].set_visible(False)
    ax.tick_params(axis="y", length=0, labelsize=10.5)
    save(fig, "summer_plan_august")


if __name__ == "__main__":
    main()
