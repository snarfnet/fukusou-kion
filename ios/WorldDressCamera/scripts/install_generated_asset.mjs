import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";

const [input, assetID] = process.argv.slice(2);
if (!input || !assetID) {
  console.error("Usage: node install_generated_asset.mjs <source.png> <asset-id>");
  process.exit(2);
}

const project = path.resolve(import.meta.dirname, "..");
const imageSet = path.join(project, "WorldDressCamera", "Assets.xcassets", `${assetID}.imageset`);
const source = path.join(imageSet, "source.png");
const output = path.join(imageSet, `${assetID}.png`);
fs.mkdirSync(imageSet, { recursive: true });
fs.copyFileSync(path.resolve(input), source);

const home = process.env.USERPROFILE;
const helper = path.join(home, ".codex", "skills", ".system", "imagegen", "scripts", "remove_chroma_key.py");
const result = spawnSync("python", [
  helper, "--input", source, "--out", output, "--auto-key", "border",
  "--soft-matte", "--transparent-threshold", "12", "--opaque-threshold", "220", "--despill"
], { stdio: "inherit" });
if (result.status !== 0) process.exit(result.status ?? 1);

const normalized = path.join(imageSet, "normalized.png");
const normalize = spawnSync("magick", [
  output, "-trim", "+repage", "-resize", "900x1220>",
  "-background", "none", "-gravity", "south", "-extent", "1024x1450",
  "-gravity", "north", "-extent", "1024x1536", normalized
], { stdio: "inherit" });
if (normalize.status !== 0) process.exit(normalize.status ?? 1);
fs.renameSync(normalized, output);
fs.rmSync(source);

const contents = {
  images: [{ filename: `${assetID}.png`, idiom: "universal", scale: "1x" }],
  info: { author: "xcode", version: 1 }
};
fs.writeFileSync(path.join(imageSet, "Contents.json"), JSON.stringify(contents, null, 2) + "\n");
console.log(`Installed ${assetID}`);
