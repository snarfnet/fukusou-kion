import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";

const project = path.resolve(import.meta.dirname, "..");
const catalogPath = path.join(project, "WorldDressCamera", "garments.json");
const assetsPath = path.join(project, "WorldDressCamera", "Assets.xcassets");
const catalog = JSON.parse(fs.readFileSync(catalogPath, "utf8"));
const errors = [];
const genders = {
  women: catalog.filter(x => x.gender === "女性").length,
  men: catalog.filter(x => x.gender === "男性").length
};

if (catalog.length !== 100) errors.push(`catalog count: ${catalog.length}`);
if (genders.women !== 50 || genders.men !== 50) errors.push(`gender counts: ${JSON.stringify(genders)}`);
if (new Set(catalog.map(x => x.id)).size !== catalog.length) errors.push("duplicate catalog IDs");

for (const garment of catalog) {
  const imageSet = path.join(assetsPath, `${garment.id}.imageset`);
  const png = path.join(imageSet, `${garment.id}.png`);
  const contents = path.join(imageSet, "Contents.json");
  if (!fs.existsSync(png) || !fs.existsSync(contents)) {
    errors.push(`${garment.id}: missing PNG or Contents.json`);
    continue;
  }
  const metadata = JSON.parse(fs.readFileSync(contents, "utf8"));
  if (metadata.images?.[0]?.filename !== `${garment.id}.png`) {
    errors.push(`${garment.id}: Contents filename mismatch`);
  }
  const identify = spawnSync("magick", [
    "identify", "-format", "%w %h %[channels] %[pixel:p{0,0}]", png
  ], { encoding: "utf8" });
  if (identify.status !== 0) {
    errors.push(`${garment.id}: unreadable PNG`);
    continue;
  }
  const [width, height, channels, ...cornerParts] = identify.stdout.trim().split(/\s+/);
  const corner = cornerParts.join(" ");
  if (!channels.toLowerCase().includes("a")) errors.push(`${garment.id}: no alpha channel`);
  if (!corner.includes(",0)") && !corner.includes(",0.0)")) errors.push(`${garment.id}: corner is not transparent (${corner})`);
  if (Number(width) !== 1024 || Number(height) !== 1536) {
    errors.push(`${garment.id}: expected 1024x1536, got ${width}x${height}`);
  }
}

console.log(JSON.stringify({
  catalog: catalog.length,
  women: genders.women,
  men: genders.men,
  verified: catalog.length - errors.length,
  errors
}, null, 2));
process.exit(errors.length ? 1 : 0);
