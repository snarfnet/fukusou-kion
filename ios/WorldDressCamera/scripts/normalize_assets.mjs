import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";

const project = path.resolve(import.meta.dirname, "..");
const catalog = JSON.parse(fs.readFileSync(path.join(project, "WorldDressCamera", "garments.json"), "utf8"));
const assets = path.join(project, "WorldDressCamera", "Assets.xcassets");

for (const [index, garment] of catalog.entries()) {
  const imageSet = path.join(assets, `${garment.id}.imageset`);
  const input = path.join(imageSet, `${garment.id}.png`);
  const output = path.join(imageSet, "normalized.png");
  const result = spawnSync("magick", [
    input, "-trim", "+repage", "-resize", "900x1220>",
    "-background", "none", "-gravity", "south", "-extent", "1024x1450",
    "-gravity", "north", "-extent", "1024x1536", output
  ], { stdio: "inherit" });
  if (result.status !== 0) {
    console.error(`Failed: ${garment.id}`);
    process.exit(result.status ?? 1);
  }
  fs.renameSync(output, input);
  if ((index + 1) % 10 === 0) console.log(`Normalized ${index + 1}/${catalog.length}`);
}
