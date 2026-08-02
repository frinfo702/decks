# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib==3.10.5"]
# ///
"""Generate the overlaid autoencoder loss chart."""

from _common import configure, plot_dagshub_loss


def main() -> None:
    configure()
    plot_dagshub_loss(
        "オートエンコーダ",
        lambda name: name.startswith("autoencoder-"),
        "dagshub_loss_autoencoder",
    )


if __name__ == "__main__":
    main()
