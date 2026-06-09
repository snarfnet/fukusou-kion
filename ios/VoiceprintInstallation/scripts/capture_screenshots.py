#!/usr/bin/env python3
import json
import math
import shutil
import struct
import subprocess
import sys
import time
import zlib
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

STATIC_DIMENSIONS = {
    "iphone67": (1290, 2796),
    "iphone65": (1242, 2688),
    "ipad129": (2048, 2732),
}

PALETTES = [
    [(0, 229, 255), (255, 58, 183), (255, 235, 128), (119, 255, 202)],
    [(255, 94, 125), (68, 214, 255), (162, 255, 95), (238, 125, 255)],
    [(103, 232, 249), (244, 114, 182), (250, 204, 21), (52, 211, 153)],
]


def png_chunk(name, payload):
    chunk_type = name.encode("ascii")
    return (
        struct.pack(">I", len(payload))
        + chunk_type
        + payload
        + struct.pack(">I", zlib.crc32(chunk_type + payload) & 0xFFFFFFFF)
    )


def write_png(path, width, height, rows):
    raw = bytearray()
    for row in rows:
        raw.append(0)
        raw.extend(row)
    payload = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    with open(path, "wb") as file:
        file.write(b"\x89PNG\r\n\x1a\n")
        file.write(png_chunk("IHDR", payload))
        file.write(png_chunk("IDAT", zlib.compress(bytes(raw), 6)))
        file.write(png_chunk("IEND", b""))


def blend(rows, width, height, x, y, color, alpha=1.0):
    if x < 0 or y < 0 or x >= width or y >= height:
        return
    index = x * 3
    row = rows[y]
    for channel in range(3):
        row[index + channel] = min(255, int(row[index + channel] * (1 - alpha) + color[channel] * alpha))


def draw_line(rows, width, height, x0, y0, x1, y1, color, thickness=2):
    dx = x1 - x0
    dy = y1 - y0
    steps = max(abs(dx), abs(dy), 1)
    for step in range(steps + 1):
        t = step / steps
        x = int(x0 + dx * t)
        y = int(y0 + dy * t)
        for ox in range(-thickness, thickness + 1):
            for oy in range(-thickness, thickness + 1):
                if ox * ox + oy * oy <= thickness * thickness:
                    blend(rows, width, height, x + ox, y + oy, color, 0.92)


def draw_polyline(rows, width, height, points, color, thickness=2):
    for first, second in zip(points, points[1:]):
        draw_line(rows, width, height, first[0], first[1], second[0], second[1], color, thickness)


def draw_orbit(rows, width, height, cx, cy, rx, ry, color, phase=0.0, thickness=2):
    points = []
    for index in range(240):
        angle = index / 239 * math.tau
        wobble = 1 + 0.08 * math.sin(angle * 5 + phase)
        x = int(cx + math.cos(angle) * rx * wobble)
        y = int(cy + math.sin(angle) * ry * wobble)
        points.append((x, y))
    draw_polyline(rows, width, height, points, color, thickness)


def draw_voice_animal(rows, width, height, palette, variant):
    cx = width // 2
    cy = int(height * 0.42)
    scale = min(width, height) / 1000

    draw_orbit(rows, width, height, cx, cy, int(270 * scale), int(180 * scale), palette[0], variant, 2)
    draw_orbit(rows, width, height, cx, cy, int(210 * scale), int(135 * scale), palette[1], variant + 0.8, 2)

    head = [
        (cx - int(170 * scale), cy - int(60 * scale)),
        (cx - int(80 * scale), cy - int(150 * scale)),
        (cx + int(95 * scale), cy - int(135 * scale)),
        (cx + int(175 * scale), cy - int(40 * scale)),
        (cx + int(150 * scale), cy + int(105 * scale)),
        (cx + int(20 * scale), cy + int(175 * scale)),
        (cx - int(135 * scale), cy + int(95 * scale)),
        (cx - int(170 * scale), cy - int(60 * scale)),
    ]
    draw_polyline(rows, width, height, head, palette[2], 3)

    for side in (-1, 1):
        wing = []
        for index in range(80):
            t = index / 79
            x = cx + side * int((120 + 430 * t) * scale)
            y = cy - int((30 + math.sin(t * math.pi) * 210 - t * 80) * scale)
            wing.append((x, y))
        draw_polyline(rows, width, height, wing, palette[side % len(palette)], 2)
        for rib in range(7):
            t = 0.14 + rib * 0.11
            x1 = cx + side * int(150 * scale)
            y1 = cy - int(25 * scale)
            x2 = cx + side * int((170 + 360 * t) * scale)
            y2 = cy - int((30 + math.sin(t * math.pi) * 190 - t * 70) * scale)
            draw_line(rows, width, height, x1, y1, x2, y2, palette[3], 1)

    eye_y = cy - int(35 * scale)
    for side in (-1, 1):
        draw_orbit(rows, width, height, cx + side * int(62 * scale), eye_y, int(34 * scale), int(20 * scale), palette[0], variant, 1)

    for band in range(18):
        y = int(height * (0.66 + band * 0.013))
        points = []
        for x in range(int(width * 0.15), int(width * 0.85), max(8, int(width / 180))):
            wave = math.sin(x * 0.015 + band * 0.7 + variant) * 18 * scale
            points.append((x, int(y + wave)))
        draw_polyline(rows, width, height, points, palette[band % len(palette)], 1)


def draw_interface_marks(rows, width, height, palette, label_index):
    margin = int(width * 0.07)
    top = int(height * 0.08)
    bottom = int(height * 0.91)
    draw_line(rows, width, height, margin, top, width - margin, top, palette[0], 2)
    draw_line(rows, width, height, margin, bottom, width - margin, bottom, palette[1], 2)
    for index in range(10):
        x = int(margin + index * (width - margin * 2) / 9)
        y = int(height * 0.78 + math.sin(index + label_index) * height * 0.025)
        draw_orbit(rows, width, height, x, y, int(width * 0.018), int(width * 0.018), palette[index % len(palette)], index, 1)
    for index in range(14):
        x = int(width * (0.14 + 0.72 * ((index * 37) % 100) / 100))
        y = int(height * (0.14 + 0.48 * ((index * 19) % 100) / 100))
        draw_line(rows, width, height, x - 9, y, x + 9, y, palette[index % len(palette)], 1)
        draw_line(rows, width, height, x, y - 9, x, y + 9, palette[index % len(palette)], 1)


def make_static_screenshot(path, width, height, variant):
    rows = []
    for y in range(height):
        row = bytearray(width * 3)
        for x in range(width):
            base = 4 + int(10 * y / height)
            pulse = int(8 * math.sin((x * 0.008) + (y * 0.006) + variant))
            index = x * 3
            row[index] = max(0, base + pulse // 3)
            row[index + 1] = max(0, base + pulse // 4)
            row[index + 2] = max(0, base + pulse)
        rows.append(row)

    palette = PALETTES[variant % len(PALETTES)]
    draw_interface_marks(rows, width, height, palette, variant)
    draw_voice_animal(rows, width, height, palette, variant * 0.61)
    write_png(path, width, height, rows)


def generate_static_screenshots(output_root):
    if output_root.exists():
        shutil.rmtree(output_root)
    output_root.mkdir(parents=True)
    for kind, (width, height) in STATIC_DIMENSIONS.items():
        for index, (label, _scroll_offset) in enumerate(SCREENSHOTS):
            path = output_root / f"{kind}_{label}.png"
            make_static_screenshot(path, width, height, index + len(kind))
            print(f"Wrote static screenshot: {path}", flush=True)


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

    generate_static_screenshots(output_root)


if __name__ == "__main__":
    raise SystemExit(main())
