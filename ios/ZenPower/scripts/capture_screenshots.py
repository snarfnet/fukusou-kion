#!/usr/bin/env python3
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

BUNDLE_ID = "com.tokyonasu.zenpower"

DEVICE_CANDIDATES = {
    "iphone_69": [
        "iPhone 17 Pro Max",
        "iPhone 16 Pro Max",
        "iPhone 15 Pro Max",
    ],
    "ipad_13": [
        "iPad Pro 13-inch (M4)",
        "iPad Pro (12.9-inch) (6th generation)",
        "iPad Pro (12.9-inch) (5th generation)",
    ],
}

SCREENSHOT_PLAN = [
    ("ja", "today", "01-home"),
    ("ja", "zazen", "02-zazen"),
    ("ja", "learn", "03-learn"),
    ("ja", "log", "04-log"),
    ("en", "today", "01-home"),
    ("en", "zazen", "02-zazen"),
    ("en", "learn", "03-learn"),
    ("en", "log", "04-log"),
]


def run(args, check=True, timeout=120):
    print("+", " ".join(str(arg) for arg in args), flush=True)
    return subprocess.run(args, check=check, text=True, capture_output=False, timeout=timeout)


def output(args):
    return subprocess.check_output(args, text=True)


def simctl_json(*args):
    return json.loads(output(["xcrun", "simctl", *args, "-j"]))


def latest_ios_runtime_identifier():
    runtimes = simctl_json("list", "runtimes")["runtimes"]
    ios_runtimes = [
        runtime for runtime in runtimes
        if runtime.get("isAvailable") and runtime.get("platform") == "iOS"
    ]
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
    names = ", ".join(device_type.get("name", "") for device_type in device_types)
    raise RuntimeError(f"No matching simulator type for {kind}. Available: {names}")


def create_device(kind, runtime_id):
    device_type_id, device_name = device_type_identifier(kind)
    name = f"ZenPower-{kind}-{int(time.time())}"
    udid = output(["xcrun", "simctl", "create", name, device_type_id, runtime_id]).strip()
    print(f"Created {device_name}: {udid}", flush=True)
    return udid


def screenshot_device(kind, app_path, output_root):
    runtime_id = latest_ios_runtime_identifier()
    udid = create_device(kind, runtime_id)
    try:
        run(["xcrun", "simctl", "boot", udid], timeout=60)
        run(["xcrun", "simctl", "bootstatus", udid, "-b"], timeout=180)
        run(["xcrun", "simctl", "install", udid, app_path])

        for language, tab, filename in SCREENSHOT_PLAN:
            out_dir = output_root / kind / language
            out_dir.mkdir(parents=True, exist_ok=True)
            out_path = out_dir / f"{filename}.png"

            run([
                "xcrun", "simctl", "launch", "--terminate-running-process", udid, BUNDLE_ID,
                f"ZEN_SCREENSHOT_TAB={tab}",
                f"ZEN_FORCE_LANGUAGE={language}",
                "ZEN_DISABLE_ADS=1",
            ], timeout=60)
            time.sleep(3)
            run(["xcrun", "simctl", "io", udid, "screenshot", str(out_path)], timeout=60)
    finally:
        run(["xcrun", "simctl", "shutdown", udid], check=False, timeout=60)
        run(["xcrun", "simctl", "delete", udid], check=False, timeout=60)


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

    kinds = [kind.strip() for kind in os.environ.get("ZEN_SCREENSHOT_KINDS", "iphone_69").split(",") if kind.strip()]
    for kind in kinds:
        screenshot_device(kind, str(app_path), output_root)


if __name__ == "__main__":
    raise SystemExit(main())
