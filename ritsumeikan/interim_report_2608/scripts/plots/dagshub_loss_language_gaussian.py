# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib==3.10.5"]
# ///
"""Generate the overlaid Language Gaussian loss chart."""

from _common import configure, plot_dagshub_loss


def main() -> None:
    configure()
    plot_dagshub_loss(
        "Language Gaussian",
        lambda name: "-feature-level-" in name,
        "dagshub_loss_language_gaussian",
    )


if __name__ == "__main__":
    main()
