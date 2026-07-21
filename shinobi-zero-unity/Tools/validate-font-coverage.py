from pathlib import Path
import bisect
import re
import struct

ROOT = Path(__file__).resolve().parents[1]
FONT = ROOT / "Assets/ShinobiZero/Fonts/NotoSansJP-Variable.ttf"
SOURCE = ROOT / "Assets/ShinobiZero"


def u16(data, offset):
    return struct.unpack_from(">H", data, offset)[0]


def u32(data, offset):
    return struct.unpack_from(">I", data, offset)[0]


def format12_ranges(data):
    table_count = u16(data, 4)
    cmap_offset = None
    for index in range(table_count):
        record = 12 + index * 16
        if data[record:record + 4] == b"cmap":
            cmap_offset = u32(data, record + 8)
            break
    if cmap_offset is None:
        raise ValueError("Font contains no cmap table")

    candidates = []
    encoding_count = u16(data, cmap_offset + 2)
    for index in range(encoding_count):
        record = cmap_offset + 4 + index * 8
        platform = u16(data, record)
        encoding = u16(data, record + 2)
        subtable = cmap_offset + u32(data, record + 4)
        if u16(data, subtable) == 12 and (platform == 0 or (platform == 3 and encoding == 10)):
            candidates.append(subtable)
    if not candidates:
        raise ValueError("Font contains no Unicode format 12 cmap")

    subtable = candidates[0]
    group_count = u32(data, subtable + 12)
    ranges = []
    for index in range(group_count):
        group = subtable + 16 + index * 12
        ranges.append((u32(data, group), u32(data, group + 4)))
    return ranges


def contains(ranges, codepoint):
    starts = [item[0] for item in ranges]
    index = bisect.bisect_right(starts, codepoint) - 1
    return index >= 0 and codepoint <= ranges[index][1]


font_data = FONT.read_bytes()
coverage = format12_ranges(font_data)
characters = set()
string_pattern = re.compile(r'"(?:\\.|[^"\\])*"')
for source_file in SOURCE.rglob("*.cs"):
    for literal in string_pattern.findall(source_file.read_text(encoding="utf-8")):
        characters.update(character for character in literal if ord(character) > 127)

missing = sorted(character for character in characters if not contains(coverage, ord(character)))
if missing:
    details = " ".join(f"{character}(U+{ord(character):04X})" for character in missing)
    raise SystemExit(f"Bundled font misses {len(missing)} UI characters: {details}")

print(f"SHINOBI ZERO font: {len(characters)} non-ASCII UI characters covered")
