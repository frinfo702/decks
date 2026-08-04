# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib==3.10.5"]
# ///
"""Generate the overlaid RGB 3DGS loss chart."""

from _common import configure, plot_dagshub_loss


def main() -> None:
    configure()
    plot_dagshub_loss(
        "RGB 3DGS",
        lambda name: name.endswith("-rgb-3dgs"),
        "dagshub_loss_rgb_3dgs",
    )


if __name__ == "__main__":
    main()
