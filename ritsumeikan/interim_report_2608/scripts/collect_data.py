#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "mlflow==3.15.0",
# ]
# ///
"""Collect reproducible source data for ISSUE-1673 without creating slides."""

from __future__ import annotations

import base64
import csv
import hashlib
import json
import os
import shutil
import subprocess
import urllib.error
import urllib.request
from collections import Counter
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from mlflow import MlflowClient


ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = ROOT.parents[1]
RAW = ROOT / "data" / "raw"
PROCESSED = ROOT / "data" / "processed"
ASSETS = ROOT / "assets" / "source" / "lerf_ovs"
PRIOR_DECK_ASSETS = ROOT / "assets" / "source" / "prior_deck"
DAGSHUB_ASSETS = ROOT / "assets" / "source" / "dagshub"
GITHUB_REPOS = (
    "frinfo702/ov-seg",
    "frinfo702/3dgs-relationship-recognition",
)
HF_REPO = "frinfo702-hf/LERF-OVS"
HF_REVISION = "dbca50acda5aeaaebaa393e46a076220d912fd66"
HF_SELECTED_FILES = (
    "README.md",
    "label/figurines/frame_00041.jpg",
    "label/figurines/frame_00041.json",
    "label/ramen/frame_00060.jpg",
    "label/ramen/frame_00060.json",
    "label/teatime/frame_00107.jpg",
    "label/teatime/frame_00107.json",
    "label/teatime_experiment/frame_00107.jpg",
    "label/teatime_experiment/frame_00107.json",
    "label/waldo_kitchen/frame_00140.jpg",
    "label/waldo_kitchen/frame_00140.json",
)
PRIOR_DECK_FILES = (
    "apple.png",
    "bag-of-cookies.png",
    "bear-nose.png",
    "coffee-next-to-apple.png",
    "coffee.png",
    "glass-next-to-apple.png",
    "sofa-feature.gif",
    "sofa-original.gif",
)
DAGSHUB_TRACKING_URI = (
    "https://dagshub.com/frinfo702/3dgs-relationship-recognition.mlflow"
)
DAGSHUB_HISTORY_KEYS = {
    "train/total_loss",
    "train/l1_loss",
    "train/l2_loss",
    "train/cos_loss",
    "train/loss_ema",
    "validation/loss",
    "train/psnr",
    "monitor/train/feature_cosine_similarity",
    "monitor/train/feature_mae_valid",
}


def run(command: list[str], *, cwd: Path | None = None) -> str:
    completed = subprocess.run(
        command,
        cwd=cwd,
        check=True,
        text=True,
        capture_output=True,
    )
    return completed.stdout


def write_csv(path: Path, fieldnames: list[str], rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def collect_github() -> None:
    commits: list[dict[str, Any]] = []
    pull_requests: list[dict[str, Any]] = []

    for repo in GITHUB_REPOS:
        commit_data = json.loads(
            run(
                [
                    "gh",
                    "api",
                    f"repos/{repo}/commits?since=2026-04-01T00:00:00Z&per_page=100",
                ]
            )
        )
        for item in commit_data:
            commit = item["commit"]
            commits.append(
                {
                    "repository": repo,
                    "sha": item["sha"],
                    "authored_at": commit["author"]["date"],
                    "committed_at": commit["committer"]["date"],
                    "subject": commit["message"].splitlines()[0],
                    "url": item["html_url"],
                }
            )

        pr_data = json.loads(
            run(
                [
                    "gh",
                    "pr",
                    "list",
                    "--repo",
                    repo,
                    "--state",
                    "all",
                    "--limit",
                    "100",
                    "--json",
                    "number,title,state,createdAt,mergedAt,closedAt,url,additions,deletions,changedFiles",
                ]
            )
        )
        for item in pr_data:
            pull_requests.append({"repository": repo, **item})
            if item["state"] != "OPEN":
                continue
            pr_detail = json.loads(
                run(
                    [
                        "gh",
                        "pr",
                        "view",
                        str(item["number"]),
                        "--repo",
                        repo,
                        "--json",
                        "commits",
                    ]
                )
            )
            for commit in pr_detail.get("commits", []):
                commits.append(
                    {
                        "repository": repo,
                        "sha": commit["oid"],
                        "authored_at": commit["authoredDate"],
                        "committed_at": commit["committedDate"],
                        "subject": commit["messageHeadline"],
                        "url": f"https://github.com/{repo}/commit/{commit['oid']}",
                    }
                )

    deck_log = run(
        [
            "git",
            "log",
            "--since=2026-04-01",
            "--format=%H%x1f%aI%x1f%cI%x1f%s%x1e",
            "--",
            "ritsumeikan",
        ],
        cwd=REPO_ROOT,
    )
    for record in deck_log.split("\x1e"):
        record = record.strip()
        if not record:
            continue
        sha, authored_at, committed_at, subject = record.split("\x1f", maxsplit=3)
        commits.append(
            {
                "repository": "frinfo702/decks",
                "sha": sha,
                "authored_at": authored_at,
                "committed_at": committed_at,
                "subject": subject,
                "url": f"https://github.com/frinfo702/decks/commit/{sha}",
            }
        )

    commits = list({(row["repository"], row["sha"]): row for row in commits}.values())
    commits.sort(key=lambda row: row["authored_at"])
    write_csv(
        RAW / "github_commits.csv",
        ["repository", "sha", "authored_at", "committed_at", "subject", "url"],
        commits,
    )
    write_csv(
        RAW / "github_pull_requests.csv",
        [
            "repository",
            "number",
            "title",
            "state",
            "createdAt",
            "mergedAt",
            "closedAt",
            "additions",
            "deletions",
            "changedFiles",
            "url",
        ],
        pull_requests,
    )

    weekly: Counter[tuple[str, str]] = Counter()
    for row in commits:
        date = datetime.fromisoformat(row["authored_at"].replace("Z", "+00:00"))
        monday = date.date().fromordinal(date.date().toordinal() - date.weekday())
        repository = row["repository"].split("/")[-1]
        weekly[(monday.isoformat(), repository)] += 1
    weekly_rows = [
        {"week_start": week, "repository": repository, "commits": count}
        for (week, repository), count in sorted(weekly.items())
    ]
    write_csv(
        PROCESSED / "weekly_activity.csv",
        ["week_start", "repository", "commits"],
        weekly_rows,
    )


def collect_hugging_face() -> None:
    info = json.loads(run(["hf", "datasets", "info", HF_REPO, "--format", "json"]))
    siblings = [item["rfilename"] for item in info["siblings"]]
    scenes = sorted(
        {
            path.split("/", maxsplit=1)[0]
            for path in siblings
            if "/" in path and not path.startswith("label/")
        }
        | {
            path.split("/", maxsplit=2)[1]
            for path in siblings
            if path.startswith("label/") and path.count("/") >= 2
        }
    )
    inventory: list[dict[str, Any]] = []
    for scene in scenes:
        inventory.append(
            {
                "scene": scene,
                "rgb_frames": sum(
                    path.startswith(f"{scene}/images/")
                    and path.lower().endswith(".jpg")
                    for path in siblings
                ),
                "label_images": sum(
                    path.startswith(f"label/{scene}/") and path.lower().endswith(".jpg")
                    for path in siblings
                ),
                "label_json": sum(
                    path.startswith(f"label/{scene}/")
                    and path.lower().endswith(".json")
                    for path in siblings
                ),
                "language_feature_arrays": sum(
                    path.startswith(f"{scene}/language_features_dim3/")
                    and path.lower().endswith(".npy")
                    for path in siblings
                ),
            }
        )
    write_csv(
        RAW / "huggingface_inventory.csv",
        [
            "scene",
            "rgb_frames",
            "label_images",
            "label_json",
            "language_feature_arrays",
        ],
        inventory,
    )

    summary = {
        "repository": HF_REPO,
        "revision": info["sha"],
        "private": info["private"],
        "last_modified": info["last_modified"],
        "used_storage_bytes": info["used_storage"],
        "file_count": len(siblings),
        "scenes": scenes,
        "retrieved_at": datetime.now(UTC).isoformat(),
    }
    (RAW / "huggingface_summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    ASSETS.mkdir(parents=True, exist_ok=True)
    run(
        [
            "hf",
            "download",
            HF_REPO,
            *HF_SELECTED_FILES,
            "--repo-type",
            "dataset",
            "--revision",
            HF_REVISION,
            "--local-dir",
            str(ASSETS),
        ]
    )


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def collect_assets_manifest() -> None:
    prior_source = (
        REPO_ROOT / "ritsumeikan" / "seminar_260714" / "slidev-test" / "assets"
    )
    PRIOR_DECK_ASSETS.mkdir(parents=True, exist_ok=True)
    for filename in PRIOR_DECK_FILES:
        shutil.copy2(prior_source / filename, PRIOR_DECK_ASSETS / filename)

    rows: list[dict[str, Any]] = []
    for path in sorted((ROOT / "assets" / "source").rglob("*")):
        if (
            not path.is_file()
            or ".cache" in path.parts
            or path.name == "source_manifest.csv"
        ):
            continue
        relative = path.relative_to(ROOT).as_posix()
        if "prior_deck" in path.parts:
            origin = f"ritsumeikan/seminar_260714/slidev-test/assets/{path.name}"
            description = (
                "Prior LangSplat evaluation artifact used in the 2026-07-14 deck"
            )
        elif "dagshub" in path.parts:
            origin = (
                "mlflow://frinfo702/3dgs-relationship-recognition/"
                f"{path.relative_to(DAGSHUB_ASSETS).as_posix()}"
            )
            description = "DagsHub/MLflow experiment image artifact"
        else:
            origin = f"hf://datasets/{HF_REPO}@{HF_REVISION}/{path.relative_to(ASSETS).as_posix()}"
            description = "Selected LERF-OVS source or annotation file"
        rows.append(
            {
                "local_path": relative,
                "origin": origin,
                "sha256": sha256(path),
                "bytes": path.stat().st_size,
                "description": description,
            }
        )
    write_csv(
        ROOT / "assets" / "source" / "source_manifest.csv",
        ["local_path", "origin", "sha256", "bytes", "description"],
        rows,
    )


def request_json(
    url: str,
    *,
    username: str,
    token: str,
    payload: dict[str, Any],
) -> dict[str, Any]:
    body = json.dumps(payload).encode("utf-8")
    credentials = base64.b64encode(f"{username}:{token}".encode()).decode()
    request = urllib.request.Request(
        url,
        data=body,
        headers={
            "Authorization": f"Basic {credentials}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def collect_dagshub() -> None:
    token = os.getenv("DAGSHUB_USER_TOKEN") or os.getenv("DAGSHUB_TOKEN")
    username = os.getenv("DAGSHUB_USERNAME", "frinfo702")
    status_path = RAW / "dagshub_collection_status.json"
    run_rows: list[dict[str, Any]] = []
    metric_rows: list[dict[str, Any]] = []
    history_rows: list[dict[str, Any]] = []
    parameter_rows: list[dict[str, Any]] = []
    tag_rows: list[dict[str, Any]] = []
    artifact_rows: list[dict[str, Any]] = []

    if not token:
        status = {
            "status": "authentication_required",
            "tracking_uri": DAGSHUB_TRACKING_URI,
            "message": "Set DAGSHUB_USER_TOKEN or DAGSHUB_TOKEN, then rerun collection.",
            "checked_at": datetime.now(UTC).isoformat(),
        }
    else:
        base = f"{DAGSHUB_TRACKING_URI}/api/2.0/mlflow"
        try:
            experiment_response = request_json(
                f"{base}/experiments/search",
                username=username,
                token=token,
                payload={"max_results": 1000},
            )
            experiments = experiment_response.get("experiments", [])
            experiment_ids = [item["experiment_id"] for item in experiments]
            run_response = request_json(
                f"{base}/runs/search",
                username=username,
                token=token,
                payload={"experiment_ids": experiment_ids, "max_results": 5000},
            )
            experiment_names = {
                item["experiment_id"]: item.get("name", "") for item in experiments
            }
            os.environ["MLFLOW_TRACKING_URI"] = DAGSHUB_TRACKING_URI
            os.environ["MLFLOW_TRACKING_USERNAME"] = username
            os.environ["MLFLOW_TRACKING_PASSWORD"] = token
            client = MlflowClient(tracking_uri=DAGSHUB_TRACKING_URI)
            DAGSHUB_ASSETS.mkdir(parents=True, exist_ok=True)
            for item in run_response.get("runs", []):
                info = item.get("info", {})
                data = item.get("data", {})
                run_id = info.get("run_id", "")
                run_name = info.get("run_name", "")
                run_status = info.get("status", "")
                run_rows.append(
                    {
                        "experiment_id": info.get("experiment_id", ""),
                        "experiment_name": experiment_names.get(
                            info.get("experiment_id", ""), ""
                        ),
                        "run_id": run_id,
                        "run_name": run_name,
                        "status": run_status,
                        "start_time_ms": info.get("start_time", ""),
                        "end_time_ms": info.get("end_time", ""),
                        "artifact_uri": info.get("artifact_uri", ""),
                    }
                )
                for metric in data.get("metrics", []):
                    key = metric.get("key", "")
                    metric_rows.append(
                        {
                            "run_id": run_id,
                            "run_name": run_name,
                            "status": run_status,
                            "key": key,
                            "value": metric.get("value", ""),
                            "step": metric.get("step", ""),
                            "timestamp_ms": metric.get("timestamp", ""),
                        }
                    )
                    if key not in DAGSHUB_HISTORY_KEYS:
                        continue
                    for point in client.get_metric_history(run_id, key):
                        history_rows.append(
                            {
                                "run_id": run_id,
                                "run_name": run_name,
                                "status": run_status,
                                "key": key,
                                "value": point.value,
                                "step": point.step,
                                "timestamp_ms": point.timestamp,
                            }
                        )

                for parameter in data.get("params", []):
                    parameter_rows.append(
                        {
                            "run_id": run_id,
                            "run_name": run_name,
                            "key": parameter.get("key", ""),
                            "value": parameter.get("value", ""),
                        }
                    )
                for tag in data.get("tags", []):
                    tag_rows.append(
                        {
                            "run_id": run_id,
                            "run_name": run_name,
                            "key": tag.get("key", ""),
                            "value": tag.get("value", ""),
                        }
                    )

                root_artifacts = client.list_artifacts(run_id)
                if not any(
                    artifact.path == "images" and artifact.is_dir
                    for artifact in root_artifacts
                ):
                    continue
                safe_name = "".join(
                    character if character.isalnum() or character in "-_" else "-"
                    for character in run_name
                ).strip("-")
                run_directory = DAGSHUB_ASSETS / f"{safe_name}--{run_id[:8]}"
                client.download_artifacts(run_id, "images", dst_path=run_directory)
                for path in sorted((run_directory / "images").rglob("*")):
                    if not path.is_file():
                        continue
                    artifact_path = path.relative_to(run_directory).as_posix()
                    artifact_rows.append(
                        {
                            "run_id": run_id,
                            "run_name": run_name,
                            "status": run_status,
                            "artifact_path": artifact_path,
                            "local_path": path.relative_to(ROOT).as_posix(),
                            "bytes": path.stat().st_size,
                            "sha256": sha256(path),
                        }
                    )
            status = {
                "status": "ok",
                "experiment_count": len(experiments),
                "run_count": len(run_rows),
                "metric_count": len(metric_rows),
                "metric_history_points": len(history_rows),
                "parameter_count": len(parameter_rows),
                "tag_count": len(tag_rows),
                "image_artifact_count": len(artifact_rows),
                "image_artifact_bytes": sum(row["bytes"] for row in artifact_rows),
                "checked_at": datetime.now(UTC).isoformat(),
            }
        except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError) as error:
            status = {
                "status": "error",
                "message": str(error),
                "checked_at": datetime.now(UTC).isoformat(),
            }

    write_csv(
        RAW / "dagshub_runs.csv",
        [
            "experiment_id",
            "experiment_name",
            "run_id",
            "run_name",
            "status",
            "start_time_ms",
            "end_time_ms",
            "artifact_uri",
        ],
        run_rows,
    )
    write_csv(
        RAW / "dagshub_latest_metrics.csv",
        [
            "run_id",
            "run_name",
            "status",
            "key",
            "value",
            "step",
            "timestamp_ms",
        ],
        metric_rows,
    )
    write_csv(
        RAW / "dagshub_metric_history.csv",
        [
            "run_id",
            "run_name",
            "status",
            "key",
            "value",
            "step",
            "timestamp_ms",
        ],
        history_rows,
    )
    write_csv(
        RAW / "dagshub_parameters.csv",
        ["run_id", "run_name", "key", "value"],
        parameter_rows,
    )
    write_csv(
        RAW / "dagshub_tags.csv",
        ["run_id", "run_name", "key", "value"],
        tag_rows,
    )
    write_csv(
        RAW / "dagshub_artifacts.csv",
        [
            "run_id",
            "run_name",
            "status",
            "artifact_path",
            "local_path",
            "bytes",
            "sha256",
        ],
        artifact_rows,
    )
    status_path.write_text(
        json.dumps(status, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    PROCESSED.mkdir(parents=True, exist_ok=True)
    collect_github()
    collect_hugging_face()
    collect_dagshub()
    collect_assets_manifest()
    print(f"Collected source data under {ROOT}")


if __name__ == "__main__":
    main()
