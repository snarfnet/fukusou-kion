from pathlib import Path
import shutil
import tarfile


ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / "Vendor" / "FreePats" / "YDP-GrandPiano-SF2-20160804.tar.bz2"
DESTINATION = ROOT / "PianoPhraseLoop" / "Resources" / "SoundFonts" / "Piano.sf2"


def main() -> None:
    if not ARCHIVE.exists():
        raise SystemExit(f"SoundFont archive not found: {ARCHIVE}")

    extract_dir = ROOT / "build" / "soundfonts"
    if extract_dir.exists():
        shutil.rmtree(extract_dir)
    extract_dir.mkdir(parents=True)

    with tarfile.open(ARCHIVE, "r:bz2") as archive:
        archive.extractall(extract_dir)

    sf2_files = sorted(extract_dir.rglob("*.sf2"))
    if not sf2_files:
        raise SystemExit("No SF2 file found in FreePats archive")

    DESTINATION.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(sf2_files[0], DESTINATION)
    print(f"Prepared SoundFont: {DESTINATION}")


if __name__ == "__main__":
    main()
