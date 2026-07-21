import plistlib
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "Assets" / "Plugins" / "iOS" / "PrivacyInfo.xcprivacy"


def main():
    with MANIFEST.open("rb") as stream:
        manifest = plistlib.load(stream)
    if manifest.get("NSPrivacyTracking") is not False:
        raise SystemExit("Tracking must be false")
    if manifest.get("NSPrivacyTrackingDomains") != []:
        raise SystemExit("Tracking domains must be empty")
    if manifest.get("NSPrivacyCollectedDataTypes") != []:
        raise SystemExit("Collected data types must be empty for the current offline build")

    declarations = {
        item["NSPrivacyAccessedAPIType"]: set(item["NSPrivacyAccessedAPITypeReasons"])
        for item in manifest.get("NSPrivacyAccessedAPITypes", [])
    }
    expected = {
        "NSPrivacyAccessedAPICategoryUserDefaults": {"CA92.1"},
        "NSPrivacyAccessedAPICategoryFileTimestamp": {"C617.1"},
    }
    if declarations != expected:
        raise SystemExit(f"Required-reason declarations differ: {declarations}")
    print("SHINOBI ZERO privacy manifest: no tracking, no collection, 2 required-reason API categories validated")


if __name__ == "__main__":
    main()
