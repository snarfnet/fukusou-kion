#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TRAIN_DIR = ROOT / "processed" / "train"
VAL_DIR = ROOT / "processed" / "val"
OUT_DIR = ROOT / "models"
OUT_MODEL = OUT_DIR / "TsuchinokoCandidate.mlmodel"


def main() -> None:
    try:
        import coremltools as ct
        import turicreate as tc
    except ImportError as exc:
        raise SystemExit(
            "Training requires Python with turicreate and coremltools on macOS. "
            "Install them in a macOS environment, then rerun this script."
        ) from exc

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    train_data = tc.image_analysis.load_images(str(TRAIN_DIR), with_path=True)
    train_data["label"] = train_data["path"].apply(lambda path: Path(path).parent.name)

    model = tc.image_classifier.create(train_data, target="label", model="squeezenet_v1.1")

    if VAL_DIR.exists():
        val_data = tc.image_analysis.load_images(str(VAL_DIR), with_path=True)
        val_data["label"] = val_data["path"].apply(lambda path: Path(path).parent.name)
        print(model.evaluate(val_data))

    model.export_coreml(str(OUT_MODEL))
    spec = ct.utils.load_spec(str(OUT_MODEL))
    spec.description.metadata.shortDescription = "Tsuchinoko candidate image classifier"
    ct.utils.save_spec(spec, str(OUT_MODEL))
    print(f"saved: {OUT_MODEL}")


if __name__ == "__main__":
    main()
