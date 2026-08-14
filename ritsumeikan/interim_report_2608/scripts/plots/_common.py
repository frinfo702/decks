"""Shared plotting utilities for the interim report figures."""

from __future__ import annotations

import csv
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path

import matplotlib as mpl
import matplotlib.dates as mdates
import matplotlib.pyplot as plt
import numpy as np


ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "data" / "raw"
PROCESSED = ROOT / "data" / "processed"
PLOTS = ROOT / "plots"

INK = "#161A1D"
MUTED = "#6B7280"
GRID = "#D9DEE5"
BLUE = "#3467D6"
BLUE_LIGHT = "#B9C9EC"
GOLD = "#C89018"
GOLD_LIGHT = "#F1DDAE"
PINK = "#C45B7C"
OLIVE = "#70833F"
BACKGROUND = "#FCFCFB"

SCENE_LABELS = {
    "figurines": "figurines",
    "ramen": "ramen",
    "waldo_kitchen": "waldo kitchen",
    "teatime": "teatime",
}


def configure() -> None:
    mpl.rcParams.update(
        {
            "font.family": ["Hiragino Sans"],
            "font.size": 13,
            "axes.titlesize": 24,
            "axes.titleweight": "bold",
            "axes.labelcolor": INK,
            "axes.edgecolor": INK,
            "axes.facecolor": BACKGROUND,
            "figure.facecolor": BACKGROUND,
            "text.color": INK,
            "xtick.color": MUTED,
            "ytick.color": MUTED,
            "axes.unicode_minus": False,
            "svg.fonttype": "none",
        }
    )


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def save(fig: plt.Figure, stem: str) -> None:
    PLOTS.mkdir(parents=True, exist_ok=True)
    fig.savefig(PLOTS / f"{stem}.png", dpi=180, facecolor=BACKGROUND)
    fig.savefig(PLOTS / f"{stem}.svg", facecolor=BACKGROUND)
    plt.close(fig)


def add_header(fig: plt.Figure, title: str, subtitle: str) -> None:
    fig.text(
        0.07,
        0.94,
        title,
        fontsize=23,
        fontweight="bold",
        ha="left",
        va="top",
    )
    if subtitle:
        fig.text(
            0.07,
            0.84,
            subtitle,
            fontsize=12.5,
            color=MUTED,
            ha="left",
            va="top",
        )


def japanese_month(value: float, _position: float | None = None) -> str:
    return f"{mdates.num2date(value).month}月"


def japanese_month_day(value: float, _position: float | None = None) -> str:
    current = mdates.num2date(value)
    return f"{current.month}/{current.day}"


def dagshub_stage(run_name: str) -> str:
    if run_name.startswith("preprocess-"):
        return "Preprocess"
    if run_name.endswith("-rgb-3dgs"):
        return "RGB 3DGS"
    if run_name.startswith("autoencoder-"):
        return "Autoencoder"
    if run_name.startswith("encode-"):
        return "Feature encoding"
    if "-feature-level-" in run_name:
        return "Language Gaussian"
    return "Other"


def dagshub_scene(run_name: str) -> str:
    if run_name.startswith("preprocess-"):
        return run_name.removeprefix("preprocess-")
    if run_name.endswith("-rgb-3dgs"):
        return run_name.removesuffix("-rgb-3dgs")
    if run_name.startswith("autoencoder-"):
        return run_name.removeprefix("autoencoder-")
    if run_name.startswith("encode-"):
        return run_name.removeprefix("encode-")
    if "-feature-level-" in run_name:
        return run_name.split("-feature-level-", maxsplit=1)[0]
    return run_name


def canonical_dagshub_runs(
    runs: list[dict[str, str]], history: list[dict[str, str]]
) -> dict[str, dict[str, str]]:
    history_run_ids = {row["run_id"] for row in history}
    grouped: defaultdict[str, list[dict[str, str]]] = defaultdict(list)
    for row in runs:
        if row["run_id"] in history_run_ids:
            grouped[row["run_name"]].append(row)

    status_rank = {"FAILED": 0, "RUNNING": 1, "FINISHED": 2}
    return {
        run_name: max(
            candidates,
            key=lambda row: (
                status_rank.get(row["status"], -1),
                int(row["end_time_ms"] or row["start_time_ms"] or 0),
            ),
        )
        for run_name, candidates in grouped.items()
    }


def latest_metric_by_run(
    history: list[dict[str, str]],
) -> dict[tuple[str, str], dict[str, str]]:
    latest: dict[tuple[str, str], dict[str, str]] = {}
    for row in history:
        key = (row["run_id"], row["key"])
        previous = latest.get(key)
        if previous is None or (int(row["step"]), int(row["timestamp_ms"])) > (
            int(previous["step"]),
            int(previous["timestamp_ms"]),
        ):
            latest[key] = row
    return latest


def write_processed_csv(
    path: Path, fieldnames: list[str], rows: list[dict[str, str]]
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def prepare_dagshub_summaries() -> tuple[
    list[dict[str, str]], dict[str, dict[str, str]]
]:
    runs = read_csv(RAW / "dagshub_runs.csv")
    history = read_csv(RAW / "dagshub_metric_history.csv")
    canonical = canonical_dagshub_runs(runs, history)
    latest = latest_metric_by_run(history)

    summary_rows: list[dict[str, str]] = []
    for run_name, run in sorted(canonical.items()):
        row: dict[str, str] = {
            "stage": dagshub_stage(run_name),
            "scene": dagshub_scene(run_name),
            "run_id": run["run_id"],
            "run_name": run_name,
            "status": run["status"],
            "start_time_ms": run["start_time_ms"],
            "end_time_ms": run["end_time_ms"],
        }
        for metric, column in (
            ("train/total_loss", "final_total_loss"),
            ("train/l1_loss", "final_l1_loss"),
            ("train/psnr", "final_psnr"),
            ("validation/loss", "validation_loss"),
        ):
            point = latest.get((run["run_id"], metric))
            row[column] = point["value"] if point else ""
            row[f"{column}_step"] = point["step"] if point else ""
        summary_rows.append(row)

    status_counts = Counter(
        (dagshub_stage(row["run_name"]), row["status"]) for row in runs
    )
    status_rows = [
        {"stage": stage, "status": status, "run_count": str(count)}
        for (stage, status), count in sorted(status_counts.items())
    ]
    write_processed_csv(
        PROCESSED / "dagshub_canonical_runs.csv",
        [
            "stage",
            "scene",
            "run_id",
            "run_name",
            "status",
            "start_time_ms",
            "end_time_ms",
            "final_total_loss",
            "final_total_loss_step",
            "final_l1_loss",
            "final_l1_loss_step",
            "final_psnr",
            "final_psnr_step",
            "validation_loss",
            "validation_loss_step",
        ],
        summary_rows,
    )
    write_processed_csv(
        PROCESSED / "dagshub_run_status.csv",
        ["stage", "status", "run_count"],
        status_rows,
    )
    return history, canonical


def deduplicate_and_downsample(
    rows: list[dict[str, str]], max_points: int = 700
) -> tuple[np.ndarray, np.ndarray]:
    latest_by_step: dict[int, dict[str, str]] = {}
    for row in rows:
        step = int(row["step"])
        previous = latest_by_step.get(step)
        if previous is None or int(row["timestamp_ms"]) > int(previous["timestamp_ms"]):
            latest_by_step[step] = row
    ordered = [latest_by_step[step] for step in sorted(latest_by_step)]
    if len(ordered) > max_points:
        indexes = np.linspace(0, len(ordered) - 1, max_points, dtype=int)
        ordered = [ordered[index] for index in indexes]
    return (
        np.array([int(row["step"]) for row in ordered]),
        np.array([float(row["value"]) for row in ordered]),
    )


def moving_average(values: np.ndarray, window: int = 31) -> np.ndarray:
    if len(values) < 3:
        return values
    width = min(window, len(values) if len(values) % 2 else len(values) - 1)
    width = max(width, 3)
    padding = width // 2
    padded = np.pad(values, (padding, padding), mode="edge")
    return np.convolve(padded, np.ones(width) / width, mode="valid")


def plot_dagshub_loss(stage_label: str, predicate, stem: str) -> None:
    history, canonical = prepare_dagshub_summaries()
    rows_by_run: defaultdict[str, list[dict[str, str]]] = defaultdict(list)
    for row in history:
        if row["key"] == "train/total_loss":
            rows_by_run[row["run_id"]].append(row)

    scene_colors = {
        "figurines": BLUE,
        "ramen": GOLD,
        "waldo_kitchen": PINK,
        "teatime": OLIVE,
    }
    level_styles = {"1": "-", "2": "--", "3": ":"}
    fig, ax = plt.subplots(figsize=(9, 5.5))
    fig.subplots_adjust(left=0.14, right=0.94, top=0.80, bottom=0.20)
    add_header(fig, "Loss", "")
    plotted_count = 0
    for run_name, run in sorted(canonical.items()):
        if run["status"] != "FINISHED" or not predicate(run_name):
            continue
        points = rows_by_run.get(run["run_id"], [])
        if len(points) < 2:
            continue
        steps, values = deduplicate_and_downsample(points)
        smoothed = moving_average(values)
        scene = dagshub_scene(run_name)
        label = SCENE_LABELS[scene]
        linestyle = "-"
        if "-feature-level-" in run_name:
            level = run_name.rsplit("-", maxsplit=1)[-1]
            label += f" · L{level}"
            linestyle = level_styles[level]
        color = scene_colors[scene]
        ax.plot(steps, values, color=color, linewidth=0.7, alpha=0.12)
        ax.plot(
            steps,
            smoothed,
            color=color,
            linestyle=linestyle,
            linewidth=2.2,
            label=label,
        )
        ax.scatter(
            steps[-1],
            smoothed[-1],
            s=26,
            color=color,
            edgecolor=INK,
            linewidth=0.5,
            zorder=3,
        )
        plotted_count += 1
    ax.set_yscale("log")
    ax.grid(color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    ax.spines[["top", "right"]].set_visible(False)
    ax.set_xlabel("training step")
    ax.set_ylabel("total loss")
    ax.xaxis.set_major_formatter(
        mpl.ticker.FuncFormatter(
            lambda value, _position: (
                f"{value / 1000:.0f}k" if abs(value) >= 1000 else f"{value:.0f}"
            )
        )
    )
    ax.legend(
        frameon=False,
        fontsize=9.5 if plotted_count > 5 else 10.5,
        ncol=2 if plotted_count > 5 else 1,
        loc="best",
    )
    save(fig, stem)


def parse_week(row: dict[str, str]):
    return datetime.fromisoformat(row["week_start"]).date()
