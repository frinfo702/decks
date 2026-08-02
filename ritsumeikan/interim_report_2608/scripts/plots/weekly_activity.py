# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib==3.10.5"]
# ///
"""Generate one combined weekly research activity figure."""

from datetime import date

import matplotlib as mpl
import matplotlib.dates as mdates
import matplotlib.pyplot as plt

from _common import (
    BLUE,
    BLUE_LIGHT,
    GOLD,
    GRID,
    INK,
    PROCESSED,
    add_header,
    configure,
    japanese_month_day,
    parse_week,
    read_csv,
    save,
)


def main() -> None:
    configure()
    rows = read_csv(PROCESSED / "weekly_activity.csv")
    start = date(2026, 4, 1)
    end = date(2026, 8, 2)
    weeks = sorted({parse_week(row) for row in rows if start <= parse_week(row) <= end})
    lookup = {(parse_week(row), row["repository"]): int(row["commits"]) for row in rows}
    repositories = (
        ("ov-seg", BLUE),
        ("3dgs-relationship-recognition", GOLD),
        ("decks", BLUE_LIGHT),
    )

    fig, axes = plt.subplots(3, 1, figsize=(12, 5.2), sharex=True)
    fig.subplots_adjust(left=0.12, right=0.97, top=0.72, bottom=0.17, hspace=0.52)
    add_header(
        fig,
        "週次研究活動",
        "2026年4月1日〜8月2日・Gitコミット数は活動の補助指標",
    )
    for ax, (repository, color) in zip(axes, repositories, strict=True):
        values = [lookup.get((week, repository), 0) for week in weeks]
        ax.bar(
            weeks,
            values,
            width=5.2,
            color=color,
            edgecolor=INK,
            linewidth=0.6,
        )
        ax.set_title(repository, loc="left", fontsize=12.5, fontweight="bold", pad=3)
        ax.yaxis.set_major_locator(mpl.ticker.MaxNLocator(integer=True, nbins=4))
        ax.grid(axis="y", color=GRID, linewidth=0.8)
        ax.set_axisbelow(True)
        ax.spines[["top", "right"]].set_visible(False)
        ax.set_ylabel("commits", fontsize=10)
    axes[-1].xaxis.set_major_locator(
        mdates.WeekdayLocator(byweekday=mdates.MO, interval=2)
    )
    axes[-1].xaxis.set_major_formatter(mpl.ticker.FuncFormatter(japanese_month_day))
    axes[-1].tick_params(axis="x", rotation=30)
    save(fig, "weekly_activity")


if __name__ == "__main__":
    main()
