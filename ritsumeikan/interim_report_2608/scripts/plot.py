# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib==3.10.5"]
# ///
"""Regenerate every slide figure from its independent plotting script."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


PLOT_SCRIPTS = (
    "research_progress_completed.py",
    "research_plan_remaining.py",
    "ovseg_reproduction_miou.py",
    "ovsam3_comparison_miou.py",
    "dagshub_loss_rgb_3dgs.py",
    "dagshub_final_psnr.py",
    "dagshub_loss_language_gaussian.py",
    "dagshub_loss_autoencoder.py",
    "summer_plan_august.py",
    "summer_plan_september.py",
    "weekly_activity.py",
)


def main() -> None:
    scripts_dir = Path(__file__).resolve().parent / "plots"
    for filename in PLOT_SCRIPTS:
        script = scripts_dir / filename
        subprocess.run([sys.executable, str(script)], check=True)
        print(f"生成しました: {script.stem}")


if __name__ == "__main__":
    main()
