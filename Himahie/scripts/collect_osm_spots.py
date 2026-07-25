"""Build prefecture JSON files from a Geofabrik Japan OSM PBF extract.

OpenStreetMap data is © OpenStreetMap contributors and available under ODbL.
The script keeps uncertain attributes conservative instead of inventing them.
"""

from __future__ import annotations

import argparse
import json
import math
import re
from collections import defaultdict
from datetime import date
from pathlib import Path
from typing import Any
from urllib.request import Request, urlopen, urlretrieve

import osmium
from deduplicate_spots import deduplicate

PBF_URL = "https://download.geofabrik.de/asia/japan-latest.osm.pbf"
BOUNDARIES_URL = "https://raw.githubusercontent.com/amay077/JapanPrefGeoJson/master/japan.geojson"
PROJECT_ROOT = Path(__file__).resolve().parents[1]

PREFECTURES = [
    ("01", "北海道", 43.0642, 141.3469), ("02", "青森県", 40.8244, 140.7400),
    ("03", "岩手県", 39.7036, 141.1527), ("04", "宮城県", 38.2688, 140.8721),
    ("05", "秋田県", 39.7186, 140.1024), ("06", "山形県", 38.2404, 140.3633),
    ("07", "福島県", 37.7503, 140.4676), ("08", "茨城県", 36.3418, 140.4468),
    ("09", "栃木県", 36.5657, 139.8836), ("10", "群馬県", 36.3911, 139.0608),
    ("11", "埼玉県", 35.8569, 139.6489), ("12", "千葉県", 35.6047, 140.1233),
    ("13", "東京都", 35.6762, 139.6503), ("14", "神奈川県", 35.4478, 139.6425),
    ("15", "新潟県", 37.9026, 139.0232), ("16", "富山県", 36.6953, 137.2113),
    ("17", "石川県", 36.5947, 136.6256), ("18", "福井県", 36.0652, 136.2216),
    ("19", "山梨県", 35.6642, 138.5684), ("20", "長野県", 36.6513, 138.1810),
    ("21", "岐阜県", 35.3912, 136.7223), ("22", "静岡県", 34.9769, 138.3831),
    ("23", "愛知県", 35.1802, 136.9066), ("24", "三重県", 34.7303, 136.5086),
    ("25", "滋賀県", 35.0045, 135.8686), ("26", "京都府", 35.0116, 135.7681),
    ("27", "大阪府", 34.6863, 135.5200), ("28", "兵庫県", 34.6913, 135.1830),
    ("29", "奈良県", 34.6851, 135.8048), ("30", "和歌山県", 34.2260, 135.1675),
    ("31", "鳥取県", 35.5039, 134.2377), ("32", "島根県", 35.4723, 133.0505),
    ("33", "岡山県", 34.6618, 133.9344), ("34", "広島県", 34.3966, 132.4596),
    ("35", "山口県", 34.1860, 131.4705), ("36", "徳島県", 34.0658, 134.5593),
    ("37", "香川県", 34.3401, 134.0434), ("38", "愛媛県", 33.8416, 132.7657),
    ("39", "高知県", 33.5597, 133.5311), ("40", "福岡県", 33.6064, 130.4183),
    ("41", "佐賀県", 33.2494, 130.2988), ("42", "長崎県", 32.7448, 129.8737),
    ("43", "熊本県", 32.7898, 130.7417), ("44", "大分県", 33.2382, 131.6126),
    ("45", "宮崎県", 31.9111, 131.4239), ("46", "鹿児島県", 31.5602, 130.5581),
    ("47", "沖縄県", 26.2124, 127.6809),
]

CATEGORIES = {
    "library": ("図書館", 120, 3),
    "arts_centre": ("文化施設", 90, 4),
    "exhibition_centre": ("展示施設", 90, 4),
}

JAPANESE_TEXT = re.compile(r"[\u3040-\u30ff\u3400-\u9fff]")


def preferred_name(tags) -> str | None:
    explicit = tags.get("name:ja") or tags.get("official_name:ja")
    if explicit:
        return explicit
    name = tags.get("name")
    english = tags.get("name:en")
    if name and english and name.startswith(english):
        remainder = name[len(english):].lstrip(" /・-–—")
        if remainder and JAPANESE_TEXT.search(remainder):
            return remainder
    return name


def tag_bool(value: str | None, *, yes_values: set[str] | None = None, positive_nonzero: bool = False) -> bool | None:
    if value is None:
        return None
    normalized = value.strip().lower()
    accepted = yes_values or {"yes"}
    if normalized in accepted:
        return True
    if positive_nonzero and normalized not in {"0", "no", "none"}:
        return True
    if normalized in {"0", "no", "none"}:
        return False
    return None


def toilet_status(tags) -> bool | None:
    toilets = tags.get("toilets")
    wheelchair = tags.get("toilets:wheelchair")
    if toilets == "yes" or wheelchair in {"yes", "limited"}:
        return True
    if toilets == "no":
        return False
    return None


def point_in_ring(lon: float, lat: float, ring: list[list[float]]) -> bool:
    inside = False
    j = len(ring) - 1
    for i, (xi, yi) in enumerate(ring):
        xj, yj = ring[j]
        if (yi > lat) != (yj > lat) and lon < (xj - xi) * (lat - yi) / ((yj - yi) or 1e-15) + xi:
            inside = not inside
        j = i
    return inside


class PrefectureLookup:
    def __init__(self, geojson_path: Path):
        data = json.loads(geojson_path.read_text(encoding="utf-8"))
        self.polygons: list[tuple[str, list[list[list[float]]]]] = []
        for feature in data["features"]:
            props = feature["properties"]
            raw_code = props.get("id") or props.get("code") or props.get("pref") or props.get("N03_007")
            code = str(raw_code).zfill(2)[:2]
            geom = feature["geometry"]
            polygons = [geom["coordinates"]] if geom["type"] == "Polygon" else geom["coordinates"]
            self.polygons.append((code, polygons))

    def find(self, lon: float, lat: float) -> str | None:
        for code, polygons in self.polygons:
            for polygon in polygons:
                if polygon and point_in_ring(lon, lat, polygon[0]):
                    return code
        return None


class SpotHandler(osmium.SimpleHandler):
    def __init__(self, lookup: PrefectureLookup):
        super().__init__()
        self.lookup = lookup
        self.spots: dict[str, list[dict[str, Any]]] = defaultdict(list)
        self.seen: set[tuple[str, int]] = set()

    def node(self, node):
        if node.location.valid():
            self._accept("node", node.id, node.tags, node.location.lon, node.location.lat)

    def way(self, way):
        locations = [(n.lon, n.lat) for n in way.nodes if n.location.valid()]
        if locations:
            self._accept("way", way.id, way.tags, sum(x for x, _ in locations) / len(locations), sum(y for _, y in locations) / len(locations))

    def _accept(self, kind: str, osm_id: int, tags, lon: float, lat: float):
        amenity = tags.get("amenity")
        tourism = tags.get("tourism")
        if amenity in CATEGORIES:
            category, stay, fun = CATEGORIES[amenity]
        elif tourism in {"museum", "gallery"}:
            free_prefix = "無料" if tags.get("fee") == "no" else ""
            category, stay, fun = (f"{free_prefix}博物館" if tourism == "museum" else f"{free_prefix}ギャラリー", 90, 4)
        elif tourism == "information" and tags.get("information") in {"visitor_centre", "office"}:
            category, stay, fun = ("ビジターセンター", 45, 3)
        elif tourism == "attraction" and tags.get("fee") == "no" and (tags.get("indoor") == "yes" or tags.get("building")):
            category, stay, fun = ("無料見学施設", 60, 4)
        else:
            return
        # Japanese labels are the best fit for this Japanese-language app.
        # Keep `name` as a fallback because some facilities intentionally use
        # an English or Latin-script brand name.
        name = preferred_name(tags)
        if not name or (kind, osm_id) in self.seen:
            return
        pref = self.lookup.find(lon, lat)
        if not pref:
            return
        self.seen.add((kind, osm_id))
        fee_no = tags.get("fee") == "no" or amenity == "library"
        address = "".join(filter(None, [tags.get("addr:city"), tags.get("addr:suburb"), tags.get("addr:quarter"), tags.get("addr:housenumber")]))
        opening = tags.get("opening_hours", "営業時間未確認")
        website = tags.get("website") or tags.get("contact:website") or ""
        self.spots[pref].append({
            "id": f"osm_{kind}_{osm_id}", "name": name, "category": category,
            "latitude": round(lat, 7), "longitude": round(lon, 7), "address": address,
            "price": 0 if fee_no else -1, "indoor": tags.get("indoor") != "no",
            "airConditioned": tag_bool(tags.get("air_conditioning")),
            "hasSeats": tag_bool(tags.get("seats"), positive_nonzero=True),
            "hasToilet": toilet_status(tags),
            "hasWifi": tag_bool(tags.get("internet_access"), yes_values={"wlan", "yes"}),
            "hasPower": tag_bool(tags.get("power_supply")),
            "soloFriendly": 4, "funScore": fun, "stayScore": 3,
            "estimatedStayMinutes": stay, "openingHoursText": opening,
            "officialURL": website,
            "notes": "OpenStreetMapから収集した候補です。無料条件、冷房、座席、営業時間は利用前に確認してください。",
            "lastVerifiedAt": str(date.today()), "sourceName": "OpenStreetMap contributors",
            "sourceURL": f"https://www.openstreetmap.org/{kind}/{osm_id}", "verificationStatus": "unverified"
        })


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--work", type=Path, default=PROJECT_ROOT / ".cache/osm")
    parser.add_argument("--output", type=Path, default=PROJECT_ROOT / "Himahie/Resources")
    parser.add_argument("--pbf", type=Path)
    args = parser.parse_args()
    args.work.mkdir(parents=True, exist_ok=True)
    args.output.mkdir(parents=True, exist_ok=True)
    pbf = args.pbf or args.work / "japan-latest.osm.pbf"
    boundaries = args.work / "japan.geojson"
    remote_size = int(urlopen(Request(PBF_URL, method="HEAD")).headers["Content-Length"])
    local_size = pbf.stat().st_size if pbf.exists() else 0
    if local_size != remote_size:
        if local_size > remote_size:
            raise RuntimeError("Cached PBF is larger than the remote file. Remove it manually.")
        print(f"Downloading {PBF_URL} from {local_size / 1024 / 1024:.0f} MB", flush=True)
        request = Request(PBF_URL, headers={"Range": f"bytes={local_size}-"})
        with urlopen(request) as response, pbf.open("ab") as output:
            if local_size and response.status != 206:
                raise RuntimeError("Download server did not accept a ranged request.")
            downloaded = local_size
            next_report = ((downloaded // (100 * 1024 * 1024)) + 1) * 100 * 1024 * 1024
            while chunk := response.read(4 * 1024 * 1024):
                output.write(chunk)
                downloaded += len(chunk)
                if downloaded >= next_report:
                    print(f"Downloaded {downloaded / 1024 / 1024:.0f} / {remote_size / 1024 / 1024:.0f} MB", flush=True)
                    next_report += 100 * 1024 * 1024
    if not boundaries.exists():
        urlretrieve(BOUNDARIES_URL, boundaries)
    handler = SpotHandler(PrefectureLookup(boundaries))
    wanted_tags = [
        *(('amenity', value) for value in CATEGORIES),
        ('tourism', 'museum'), ('tourism', 'gallery'),
        ('tourism', 'information'), ('tourism', 'attraction')
    ]
    processor = (osmium.FileProcessor(str(pbf))
                 .with_locations("flex_mem")
                 .with_filter(osmium.filter.TagFilter(*wanted_tags)))
    processed = 0
    for obj in processor:
        if isinstance(obj, osmium.osm.Node) and obj.location.valid():
            handler._accept("node", obj.id, obj.tags, obj.location.lon, obj.location.lat)
        elif isinstance(obj, osmium.osm.Way):
            locations = [(node.lon, node.lat) for node in obj.nodes if node.location.valid()]
            if locations:
                handler._accept("way", obj.id, obj.tags,
                                sum(x for x, _ in locations) / len(locations),
                                sum(y for _, y in locations) / len(locations))
        processed += 1
        if processed % 5000 == 0:
            print(f"Matched OSM objects: {processed}", flush=True)
    overrides_path = args.output / "verified_spots.json"
    if overrides_path.exists():
        overrides = json.loads(overrides_path.read_text(encoding="utf-8"))
        for override in overrides:
            prefecture_code = override.pop("prefectureCode")
            current = handler.spots[prefecture_code]
            current[:] = [spot for spot in current if spot["id"] != override["id"] and spot["name"] != override["name"]]
            current.append(override)
    catalog = []
    for code, name, lat, lon in PREFECTURES:
        spots, removed_duplicates = deduplicate(handler.spots.get(code, []))
        spots = sorted(spots, key=lambda item: item["name"])
        (args.output / f"spots_{code}.json").write_text(json.dumps(spots, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
        catalog.append({"code": code, "name": name, "fileName": f"spots_{code}", "spotCount": len(spots), "centerLatitude": lat, "centerLongitude": lon})
        print(f"{code} {name}: {len(spots)} (duplicates removed: {removed_duplicates})", flush=True)
    (args.output / "prefectures.json").write_text(json.dumps(catalog, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Total: {sum(item['spotCount'] for item in catalog)}", flush=True)


if __name__ == "__main__":
    main()
