import json
import subprocess
import sys
import time
from pathlib import Path

APP_PATH = Path(sys.argv[1]).resolve()
OUTPUT = Path(sys.argv[2]).resolve()
BUNDLE_ID = "com.tokyonasu.lostinjapan"


def run(*args, capture=False):
    result = subprocess.run(args, check=True, text=True, capture_output=capture)
    return result.stdout if capture else ""


def select_runtime():
    data = json.loads(run("xcrun", "simctl", "list", "runtimes", "-j", capture=True))
    runtimes = [item for item in data["runtimes"] if item.get("isAvailable") and item["platform"] == "iOS"]
    return sorted(runtimes, key=lambda item: item["version"], reverse=True)[0]["identifier"]


def select_device(patterns):
    data = json.loads(run("xcrun", "simctl", "list", "devicetypes", "-j", capture=True))
    for pattern in patterns:
        matches = [item for item in data["devicetypes"] if pattern in item["name"]]
        if matches:
            return matches[-1]["identifier"]
    raise RuntimeError(f"No simulator device matched: {patterns}")


def capture(name, device_type, expected_group):
    runtime = select_runtime()
    udid = run("xcrun", "simctl", "create", f"LostInJapan-{name}", device_type, runtime, capture=True).strip()
    try:
        run("xcrun", "simctl", "boot", udid)
        run("xcrun", "simctl", "bootstatus", udid, "-b")
        run("xcrun", "simctl", "install", udid, str(APP_PATH))
        run("xcrun", "simctl", "status_bar", udid, "override", "--time", "9:41", "--batteryState", "charged", "--batteryLevel", "100")
        destination = OUTPUT / expected_group
        destination.mkdir(parents=True, exist_ok=True)
        screens = [("01-home.png", None), ("02-emergency.png", "emergency"), ("03-found-item.png", "found")]
        for filename, route in screens:
            args = [
                "xcrun", "simctl", "launch", "--terminate-running", udid, BUNDLE_ID,
                "-hasSelectedInitialLanguage", "YES", "-hasCompletedOnboarding", "YES", "-appLanguage", "en",
            ]
            if route:
                args += ["-screenshotRoute", route]
            run(*args)
            time.sleep(3)
            run("xcrun", "simctl", "io", udid, "screenshot", str(destination / filename))
    finally:
        subprocess.run(["xcrun", "simctl", "shutdown", udid], check=False)
        subprocess.run(["xcrun", "simctl", "delete", udid], check=False)


OUTPUT.mkdir(parents=True, exist_ok=True)
iphone = select_device(["iPhone 16 Pro Max", "iPhone 15 Pro Max", "iPhone 14 Pro Max"])
ipad = select_device(["iPad Pro 13-inch", "iPad Pro (12.9-inch)"])
capture("iPhone", iphone, "APP_IPHONE_67")
capture("iPad", ipad, "APP_IPAD_PRO_3GEN_129")
