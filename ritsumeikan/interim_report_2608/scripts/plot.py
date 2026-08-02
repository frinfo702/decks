# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "matplotlib==3.10.5",
# ]
# ///
"""Generate static, slide-ready research plots from collected CSV files."""

from __future__ import annotations

import csv
from collections import Counter, defaultdict
from collections.abc import Callable
from datetime import date, datetime
from pathlib import Path

import matplotlib as mpl
import matplotlib.dates as mdates
import matplotlib.pyplot as plt
import numpy as np


ROOT = Path(__file__).resolve().parents[1]
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
    fig.text(0.07, 0.84, subtitle, fontsize=12.5, color=MUTED, ha="left", va="top")


PHASE_LABELS = {
    "OV-Seg reproduction": "OV-Seg 再現",
    "OVSAM3 implementation": "OVSAM3 実装",
    "Research direction exploration": "研究方向の探索",
    "LangSplat environment and reproduction": "LangSplat 環境構築・再現",
    "Evaluation and failure analysis": "評価・失敗分析",
    "Experiment tracking and dataset preparation": "実験追跡・データ準備",
    "Summer implementation and evaluation": "夏期実装・評価",
    "Autumn experiments and thesis evidence": "秋期実験・論文根拠整理",
    "Thesis completion and presentation": "論文完成・最終発表",
}


def japanese_month(value: float, _position: float | None = None) -> str:
    return f"{mdates.num2date(value).month}月"


def japanese_month_day(value: float, _position: float | None = None) -> str:
    current = mdates.num2date(value)
    return f"{current.month}/{current.day}"


def research_timeline(
    rows: list[dict[str, str]],
    *,
    title: str,
    subtitle: str,
    stem: str,
    color: str,
    start: date,
    end: date,
) -> None:
    fig, ax = plt.subplots(figsize=(10, 6))
    fig.subplots_adjust(left=0.37, right=0.95, top=0.76, bottom=0.17)
    add_header(fig, title, subtitle)
    display_rows = list(reversed(rows))
    for index, row in enumerate(display_rows):
        row_start = datetime.fromisoformat(row["start_date"])
        row_end = datetime.fromisoformat(row["end_date"])
        ax.barh(
            index,
            (row_end - row_start).days + 1,
            left=mdates.date2num(row_start),
            height=0.58,
            color=color,
            edgecolor=INK,
            linewidth=0.8,
        )
    ax.set_yticks(
        range(len(display_rows)),
        [PHASE_LABELS[row["phase"]] for row in display_rows],
    )
    ax.set_xlim(start, end)
    ax.xaxis.set_major_locator(mdates.MonthLocator())
    ax.xaxis.set_major_formatter(mpl.ticker.FuncFormatter(japanese_month))
    ax.grid(axis="x", color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    ax.spines[["top", "right", "left"]].set_visible(False)
    ax.tick_params(axis="y", length=0, labelsize=11)
    save(fig, stem)


def annual_timeline() -> None:
    rows = read_csv(RAW / "research_milestones.csv")
    research_timeline(
        [row for row in rows if row["status"] == "completed"],
        title="完了した研究工程",
        subtitle="2026年4月〜7月・完了済みの工程のみ",
        stem="research_progress_completed",
        color=BLUE,
        start=date(2026, 4, 1),
        end=date(2026, 8, 1),
    )
    research_timeline(
        [row for row in rows if row["status"] == "proposed"],
        title="今後の研究計画",
        subtitle="2026年8月〜2027年3月・すべて予定",
        stem="research_plan_remaining",
        color=BLUE_LIGHT,
        start=date(2026, 8, 1),
        end=date(2027, 4, 1),
    )


def spring_result_chart(
    labels: list[str],
    values: list[float],
    *,
    title: str,
    subtitle: str,
    stem: str,
    colors: list[str],
    note: str,
) -> None:
    fig, ax = plt.subplots(figsize=(9, 5.5))
    fig.subplots_adjust(left=0.34, right=0.93, top=0.72, bottom=0.19)
    add_header(fig, title, subtitle)
    y = np.arange(len(labels))
    bars = ax.barh(y, values, color=colors, edgecolor=INK, linewidth=0.8, height=0.56)
    ax.set_yticks(y, labels)
    ax.set_xlim(0, 42)
    ax.xaxis.set_major_locator(mpl.ticker.MultipleLocator(10))
    ax.set_xlabel("mIoU（%）")
    ax.grid(axis="x", color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    ax.spines[["top", "right", "left"]].set_visible(False)
    ax.tick_params(axis="y", length=0)
    ax.bar_label(bars, fmt="%.3g", padding=5, fontsize=12)
    fig.text(0.07, 0.055, note, fontsize=10.5, color=MUTED)
    save(fig, stem)


def spring_results() -> None:
    rows = [
        row
        for row in read_csv(RAW / "evaluation_metrics.csv")
        if row["group"] == "open_vocab_segmentation" and row["metric"] == "mIoU"
    ]
    lookup = {(row["method"], row["setting"]): float(row["value"]) for row in rows}
    spring_result_chart(
        ["OV-Seg（R-101）", "OV-Seg（Swin-B）"],
        [
            lookup[("OV-Seg", "Config B: R-101 / ViT-B16")],
            lookup[("OV-Seg", "Config A: Swin-B / ViT-L14")],
        ],
        title="OV-Seg 再現結果",
        subtitle="ADE20K-150 検証データ・2026年4月",
        stem="ovseg_reproduction_miou",
        colors=[BLUE_LIGHT, BLUE],
        note="既存研究の報告値を再現した結果。",
    )
    spring_result_chart(
        ["OV-Seg（R-101）", "OVSAM3", "SAM3（参考値）"],
        [
            lookup[("OV-Seg", "Config B: R-101 / ViT-B16")],
            lookup[("OVSAM3", "SAM3 masks + fine-tuned CLIP")],
            lookup[("SAM3", "SAM3 encoder + decoder")],
        ],
        title="OVSAM3 手法置換の比較",
        subtitle="ADE20K-150 検証データ・mIoU",
        stem="ovsam3_comparison_miou",
        colors=[BLUE_LIGHT, GOLD, MUTED],
        note="SAM3は参考値。OV-SegとOVSAM3は本研究で評価。",
    )


def relation_metric_chart(
    lookup: dict[tuple[str, str], float],
    *,
    metric: str,
    metric_label: str,
    stem: str,
) -> None:
    labels = ["物体名のみ", "位置関係を追加（2件）"]
    values = [
        lookup[("object-only queries", metric)],
        lookup[("2 edited relation queries", metric)],
    ]
    fig, ax = plt.subplots(figsize=(8, 5.5))
    fig.subplots_adjust(left=0.20, right=0.93, top=0.72, bottom=0.23)
    add_header(
        fig,
        f"位置関係クエリ：{metric_label}",
        "teatime・公開済みLangSplatチェックポイント・マスク閾値0.4",
    )
    bars = ax.bar(
        np.arange(2),
        values,
        color=[BLUE, GOLD_LIGHT],
        edgecolor=INK,
        linewidth=0.8,
        hatch=[None, "///"],
        width=0.58,
    )
    ax.set_xticks(np.arange(2), labels)
    ax.set_ylim(0, 100)
    ax.set_ylabel("割合（%）")
    ax.yaxis.set_major_formatter(mpl.ticker.PercentFormatter())
    ax.grid(axis="y", color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    ax.spines[["top", "right"]].set_visible(False)
    ax.bar_label(bars, fmt="%.1f%%", padding=5, fontsize=12)
    fig.text(
        0.07,
        0.055,
        "注：変更はアノテーション2件のみ。境界矩形は未変更のため予備的な観察。",
        fontsize=10.5,
        color=PINK,
    )
    save(fig, stem)


def relation_query_comparison() -> None:
    rows = [
        row
        for row in read_csv(RAW / "evaluation_metrics.csv")
        if row["group"] == "langsplat_localization"
    ]
    lookup = {
        (row["setting"], row["metric"]): float(row["value"]) * 100 for row in rows
    }
    relation_metric_chart(
        lookup,
        metric="mIoU",
        metric_label="mIoU",
        stem="relation_query_miou",
    )
    relation_metric_chart(
        lookup,
        metric="localization_accuracy",
        metric_label="位置推定正解率",
        stem="relation_query_localization_accuracy",
    )


SUMMER_LABELS = {
    "1": "週1  パイプライン動作確認・実行ID記録",
    "2": "週2  お盆休暇・監視のみ",
    "3": "週3  5シーン実行・チェックポイント比較",
    "4": "週4  CLIP空間の不一致を診断",
    "5": "週5  Rel3D基準手法・接続確認",
    "6": "週6  クエリを主語・関係・対象へ分解",
    "7": "週7  位置推定と関係検証を接続",
    "8": "週8  位置関係対応手法を初回評価",
    "9": "週9  結果確定・秋期計画改訂",
}


def summer_plan_period(
    rows: list[dict[str, str]],
    *,
    title: str,
    subtitle: str,
    stem: str,
    start: date,
    end: date,
) -> None:
    workstream_colors = {
        "reproduction": BLUE,
        "break": MUTED,
        "diagnosis": GOLD,
        "relation_baseline": OLIVE,
        "query_parser": PINK,
        "integration": BLUE_LIGHT,
        "evaluation": GOLD_LIGHT,
        "reporting": "#AEB5BD",
    }
    fig, ax = plt.subplots(figsize=(10, 5.8))
    fig.subplots_adjust(left=0.43, right=0.95, top=0.72, bottom=0.18)
    add_header(fig, title, subtitle)
    display_rows = list(reversed(rows))
    for index, row in enumerate(display_rows):
        row_start = datetime.fromisoformat(row["start_date"])
        row_end = datetime.fromisoformat(row["end_date"])
        ax.barh(
            index,
            (row_end - row_start).days + 1,
            left=mdates.date2num(row_start),
            height=0.6,
            color=workstream_colors[row["workstream"]],
            edgecolor=INK,
            linewidth=0.8,
            hatch="///" if row["workstream"] == "break" else None,
        )
    ax.set_yticks(
        range(len(display_rows)),
        [SUMMER_LABELS[row["week"]] for row in display_rows],
    )
    ax.set_xlim(start, end)
    ax.xaxis.set_major_locator(mdates.WeekdayLocator(byweekday=mdates.MO))
    ax.xaxis.set_major_formatter(mpl.ticker.FuncFormatter(japanese_month_day))
    ax.grid(axis="x", color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    ax.spines[["top", "right", "left"]].set_visible(False)
    ax.tick_params(axis="y", length=0, labelsize=10.5)
    save(fig, stem)


def summer_plan() -> None:
    rows = read_csv(RAW / "summer_plan.csv")
    summer_plan_period(
        [row for row in rows if int(row["week"]) <= 5],
        title="夏期計画：8月開始分",
        subtitle="2026年8月3日〜9月6日・すべて予定",
        stem="summer_plan_august",
        start=date(2026, 8, 1),
        end=date(2026, 9, 7),
    )
    summer_plan_period(
        [row for row in rows if int(row["week"]) >= 6],
        title="夏期計画：9月開始分",
        subtitle="2026年9月7日〜30日・すべて予定",
        stem="summer_plan_september",
        start=date(2026, 9, 7),
        end=date(2026, 10, 1),
    )


def weekly_activity() -> None:
    rows = read_csv(PROCESSED / "weekly_activity.csv")
    start = date(2026, 4, 1)
    end = date(2026, 8, 2)
    weeks = sorted(
        {
            datetime.fromisoformat(row["week_start"]).date()
            for row in rows
            if start <= datetime.fromisoformat(row["week_start"]).date() <= end
        }
    )
    lookup = {
        (datetime.fromisoformat(row["week_start"]).date(), row["repository"]): int(
            row["commits"]
        )
        for row in rows
    }
    repositories = (
        ("ov-seg", BLUE, "ov_seg"),
        ("3dgs-relationship-recognition", GOLD, "3dgs_relationship_recognition"),
        ("decks", BLUE_LIGHT, "decks"),
    )
    for repository, color, stem_suffix in repositories:
        values = [lookup.get((week, repository), 0) for week in weeks]
        fig, ax = plt.subplots(figsize=(9, 5.5))
        fig.subplots_adjust(left=0.13, right=0.94, top=0.72, bottom=0.22)
        add_header(
            fig,
            "週次研究活動",
            f"{repository}・2026年4月1日〜8月2日・Gitコミット数は活動の補助指標",
        )
        ax.bar(
            weeks,
            values,
            width=5.2,
            color=color,
            edgecolor=INK,
            linewidth=0.6,
        )
        ax.xaxis.set_major_locator(
            mdates.WeekdayLocator(byweekday=mdates.MO, interval=2)
        )
        ax.xaxis.set_major_formatter(mpl.ticker.FuncFormatter(japanese_month_day))
        ax.yaxis.set_major_locator(mpl.ticker.MaxNLocator(integer=True))
        ax.grid(axis="y", color=GRID, linewidth=0.8)
        ax.set_axisbelow(True)
        ax.spines[["top", "right"]].set_visible(False)
        ax.tick_params(axis="x", rotation=30)
        ax.set_ylabel("週あたりコミット数")
        save(fig, f"weekly_activity_{stem_suffix}")


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
    selected: dict[str, dict[str, str]] = {}
    for run_name, candidates in grouped.items():
        selected[run_name] = max(
            candidates,
            key=lambda row: (
                status_rank.get(row["status"], -1),
                int(row["end_time_ms"] or row["start_time_ms"] or 0),
            ),
        )
    return selected


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


def prepare_dagshub_summaries() -> tuple[
    list[dict[str, str]],
    list[dict[str, str]],
    dict[str, dict[str, str]],
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
    return runs, history, canonical


def write_processed_csv(
    path: Path, fieldnames: list[str], rows: list[dict[str, str]]
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


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


SCENE_LABELS = {
    "figurines": "figurines",
    "ramen": "ramen",
    "waldo_kitchen": "waldo kitchen",
    "teatime": "teatime",
}


def dagshub_loss_curve(
    rows_by_run: dict[str, list[dict[str, str]]],
    canonical: dict[str, dict[str, str]],
    *,
    stage_label: str,
    predicate: Callable[[str], bool],
    stem: str,
) -> None:
    scene_colors = {
        "figurines": BLUE,
        "ramen": GOLD,
        "waldo_kitchen": PINK,
        "teatime": OLIVE,
    }
    fig, ax = plt.subplots(figsize=(9, 5.5))
    fig.subplots_adjust(left=0.14, right=0.94, top=0.72, bottom=0.20)
    add_header(
        fig,
        f"{stage_label} 学習損失",
        "完了済みrunのみ・総損失・対数尺度・2026年8月2日取得",
    )
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
        if "-feature-level-" in run_name:
            label += f" · L{run_name.rsplit('-', maxsplit=1)[-1]}"
        color = scene_colors[scene]
        ax.plot(steps, values, color=color, linewidth=0.7, alpha=0.12)
        ax.plot(steps, smoothed, color=color, linewidth=2.2, label=label)
        ax.scatter(
            steps[-1],
            smoothed[-1],
            s=26,
            color=color,
            edgecolor=INK,
            linewidth=0.5,
            zorder=3,
        )
    ax.set_yscale("log")
    ax.grid(color=GRID, linewidth=0.8)
    ax.set_axisbelow(True)
    ax.spines[["top", "right"]].set_visible(False)
    ax.set_xlabel("training step")
    ax.set_ylabel("total loss")
    ax.xaxis.set_major_formatter(
        mpl.ticker.FuncFormatter(
            lambda value, _position: f"{value / 1000:.0f}k"
            if abs(value) >= 1000
            else f"{value:.0f}"
        )
    )
    ax.legend(frameon=False, fontsize=10.5, loc="best")
    save(fig, stem)


def dagshub_loss_curves(
    history: list[dict[str, str]], canonical: dict[str, dict[str, str]]
) -> None:
    rows_by_run: defaultdict[str, list[dict[str, str]]] = defaultdict(list)
    for row in history:
        if row["key"] == "train/total_loss":
            rows_by_run[row["run_id"]].append(row)

    stages: tuple[tuple[str, Callable[[str], bool], str], ...] = (
        (
            "RGB 3DGS",
            lambda name: name.endswith("-rgb-3dgs"),
            "dagshub_loss_rgb_3dgs",
        ),
        (
            "Language Gaussian",
            lambda name: "-feature-level-" in name,
            "dagshub_loss_language_gaussian",
        ),
        (
            "オートエンコーダ",
            lambda name: name.startswith("autoencoder-"),
            "dagshub_loss_autoencoder",
        ),
    )
    for stage_label, predicate, stem in stages:
        dagshub_loss_curve(
            rows_by_run,
            canonical,
            stage_label=stage_label,
            predicate=predicate,
            stem=stem,
        )


def dagshub_final_psnr() -> None:
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
    colors = [BLUE_LIGHT, GOLD, BLUE]

    fig, ax = plt.subplots(figsize=(9, 5.5))
    fig.subplots_adjust(left=0.25, right=0.92, top=0.72, bottom=0.18)
    add_header(
        fig,
        "RGB 3DGS 再構成品質",
        "完了済み実行の最終PSNR・30,000ステップ",
    )
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


def main() -> None:
    configure()
    annual_timeline()
    spring_results()
    relation_query_comparison()
    summer_plan()
    weekly_activity()
    _runs, history, canonical = prepare_dagshub_summaries()
    dagshub_loss_curves(history, canonical)
    dagshub_final_psnr()
    print(f"プロットを生成しました: {PLOTS}")


if __name__ == "__main__":
    main()
