# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib==3.10.5"]
# ///
"""Generate the OV-Seg reproduction mIoU chart."""

import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np

from _common import (
    BLUE,
    BLUE_LIGHT,
    GRID,
    INK,
    MUTED,
    RAW,
    add_header,
    configure,
    read_csv,
    save,
)


def main() -> None:
    configure()
    rows = [
        row
        for row in read_csv(RAW / "evaluation_metrics.csv")
        if row["group"] == "open_vocab_segmentation" and row["metric"] == "mIoU"
    ]
    lookup = {(row["method"], row["setting"]): float(row["value"]) for row in rows}
    labels = ["OV-Seg（R-101）", "OV-Seg（Swin-B）"]
    values = [
        lookup[("OV-Seg", "Config B: R-101 / ViT-B16")],
        lookup[("OV-Seg", "Config A: Swin-B / ViT-L14")],
    ]
    fig, ax = plt.subplots(figsize=(9, 5.5))
    fig.subplots_adjust(left=0.34, right=0.93, top=0.72, bottom=0.19)
    add_header(fig, "OV-Seg 再現結果", "ADE20K-150 検証データ・2026年4月")
    y = np.arange(len(labels))
    bars = ax.barh(
        y,
        values,
        color=[BLUE_LIGHT, BLUE],
        edgecolor=INK,
        linewidth=0.8,
        height=0.56,
    )
    ax.set_yticks(y, labels)
    ax.set_xlim(0, 42)
    ax.xaxis.set_major_locator(mpl.ticker.MultipleLocator(10))
    ax.set_xlabel("mIoU（%）")
    ax.grid(axis="x", color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    ax.spines[["top", "right", "left"]].set_visible(False)
    ax.tick_params(axis="y", length=0)
    ax.bar_label(bars, fmt="%.3g", padding=5, fontsize=12)
    fig.text(
        0.07, 0.055, "既存研究の報告値を再現した結果。", fontsize=10.5, color=MUTED
    )
    save(fig, "ovseg_reproduction_miou")


if __name__ == "__main__":
    main()
