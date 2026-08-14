# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib==3.10.5"]
# ///
"""Generate the final RGB 3DGS PSNR comparison chart."""

import matplotlib.pyplot as plt
import numpy as np

from _common import (
    BLUE,
    GOLD,
    GRID,
    INK,
    PINK,
    PROCESSED,
    SCENE_LABELS,
    add_header,
    configure,
    prepare_dagshub_summaries,
    read_csv,
    save,
)


def main() -> None:
    configure()
    prepare_dagshub_summaries()
    rows = [
        row
        for row in read_csv(PROCESSED / "dagshub_canonical_runs.csv")
        if row["stage"] == "RGB 3DGS"
        and row["status"] == "FINISHED"
        and row["final_psnr"]
    ]
    rows.sort(key=lambda row: float(row["final_psnr"]))
    labels = [SCENE_LABELS[row["scene"]] for row in rows]
    values = [float(row["final_psnr"]) for row in rows]
    scene_colors = {"figurines": BLUE, "ramen": GOLD, "waldo_kitchen": PINK}
    colors = [scene_colors[row["scene"]] for row in rows]

    fig, ax = plt.subplots(figsize=(9, 5.5))
    fig.subplots_adjust(left=0.25, right=0.92, top=0.80, bottom=0.18)
    add_header(fig, "PSNR", "")
    bars = ax.barh(
        np.arange(len(rows)),
        values,
        color=colors[: len(rows)],
        edgecolor=INK,
        linewidth=0.8,
        height=0.58,
    )
    ax.set_yticks(np.arange(len(rows)), labels)
    ax.set_xlim(0, max(values) + 4)
    ax.grid(axis="x", color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    ax.spines[["top", "right", "left"]].set_visible(False)
    ax.tick_params(axis="y", length=0)
    ax.set_xlabel("PSNR（dB）")
    ax.bar_label(bars, fmt="%.2f dB", padding=7, fontsize=12)
    save(fig, "dagshub_final_psnr")


if __name__ == "__main__":
    main()
