#!/usr/bin/env python3
import json
import shutil
import subprocess
import sys
import time
from pathlib import Path

BUNDLE_ID = "com.tokyonasu.voiceprintinstallation"

DEVICE_CANDIDATES = {
    "iphone67": ["iPhone 16 Pro Max", "iPhone 15 Pro Max", "iPhone 14 Pro Max"],
    "iphone65": ["iPhone 11 Pro Max", "iPhone XS Max"],
    "ipad129": ["iPad Pro 13-inch (M4)", "iPad Pro (12.9-inch) (6th generation)", "iPad Pro (12.9-inch) (5th generation)"],
}

SCREENSHOTS = [
    ("01_studio", 0),
    ("02_gallery", 420),
    ("03_nft_prep", 260),
]


def run(args, check=True, timeout=180):
    print("+", " ".join(str(arg) for arg in args), flush=True)
    try:
        return subprocess.run(args, check=check, text=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        if not check:
            print(f"Command timed out after {timeout}s; continuing.", flush=True)
            return None
        raise


def output(args):
    return subprocess.check_output(args, text=True)


def simctl_json(*args):
    return json.loads(output(["xcrun", "simctl", *args, "-j"]))


def latest_ios_runtime_identifier():
    runtimes = simctl_json("list", "runtimes")["runtimes"]
    ios_runtimes = [runtime for runtime in runtimes if runtime.get("isAvailable") and runtime.get("platform") == "iOS"]
    if not ios_runtimes:
        raise RuntimeError("No available iOS simulator runtime found")
    ios_runtimes.sort(key=lambda runtime: tuple(int(part) for part in runtime["version"].split(".")))
    return ios_runtimes[-1]["identifier"]


def device_type_identifier(kind):
    device_types = simctl_json("list", "devicetypes")["devicetypes"]
    for candidate in DEVICE_CANDIDATES[kind]:
        for device_type in device_types:
            if device_type.get("name") == candidate:
                return device_type["identifier"], candidate
    available = ", ".join(device_type.get("name", "") for device_type in device_types)
    raise RuntimeError(f"No matching simulator type for {kind}. Available: {available}")


def create_device(kind, runtime_id):
    device_type_id, device_name = device_type_identifier(kind)
    name = f"VoiceprintNFT-{kind}-{int(time.time())}"
    udid = output(["xcrun", "simctl", "create", name, device_type_id, runtime_id]).strip()
    print(f"Created {device_name}: {udid}", flush=True)
    return udid


def screenshot_device(kind, app_path, output_root):
    runtime_id = latest_ios_runtime_identifier()
    udid = create_device(kind, runtime_id)
    try:
        run(["xcrun", "simctl", "boot", udid], timeout=90)
        run(["xcrun", "simctl", "bootstatus", udid, "-b"], timeout=240)
        run(["xcrun", "simctl", "install", udid, app_path], timeout=180)

        for label, scroll_offset in SCREENSHOTS:
            filename = f"{kind}_{label}.png"
            out_path = output_root / filename
            run([
                "xcrun", "simctl", "launch", "--terminate-running-process", udid, BUNDLE_ID,
                "--screenshot-demo",
            ], timeout=90)
            time.sleep(3)
            if scroll_offset:
                run([
                    "xcrun", "simctl", "ui", udid, "scroll",
                    "0", str(scroll_offset),
                ], check=False, timeout=30)
                time.sleep(1)
            run(["xcrun", "simctl", "io", udid, "screenshot", str(out_path)], timeout=180)
    finally:
        run(["xcrun", "simctl", "shutdown", udid], check=False, timeout=90)
        run(["xcrun", "simctl", "delete", udid], check=False, timeout=90)


def main():
    if len(sys.argv) != 3:
        print("Usage: capture_screenshots.py <app-path> <output-dir>", file=sys.stderr)
        return 2

    app_path = Path(sys.argv[1]).resolve()
    output_root = Path(sys.argv[2]).resolve()
    if not app_path.exists():
        raise RuntimeError(f"App not found: {app_path}")

    if output_root.exists():
        shutil.rmtree(output_root)
    output_root.mkdir(parents=True)

    for kind in ["iphone67", "iphone65", "ipad129"]:
        screenshot_device(kind, str(app_path), output_root)


if __name__ == "__main__":
    raise SystemExit(main())
