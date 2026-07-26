import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";

const root = path.resolve(import.meta.dirname, "..");
const app = path.join(root, "WorldDressCamera");
const pbx = fs.readFileSync(path.join(root, "WorldDressCamera.xcodeproj", "project.pbxproj"), "utf8");
const requiredSwift = [
  "WorldDressCameraApp.swift", "ContentView.swift", "Models.swift", "ImagePicker.swift",
  "FullBodyGuide.swift", "ImageComposer.swift"
];
const errors = [];

for (const name of requiredSwift) {
  if (!fs.existsSync(path.join(app, name))) errors.push(`missing ${name}`);
  if (!pbx.includes(`${name} in Sources`)) errors.push(`project does not compile ${name}`);
}
for (const name of ["Assets.xcassets", "garments.json"]) {
  if (!pbx.includes(`${name} in Resources`)) errors.push(`project does not bundle ${name}`);
}
for (const name of ["Info.plist", "garments.json"]) {
  if (!fs.existsSync(path.join(app, name))) errors.push(`missing ${name}`);
}

const plist = spawnSync("plutil", ["-lint", path.join(app, "Info.plist")], { encoding: "utf8" });
if (plist.status !== 0) errors.push("invalid Info.plist");
const project = spawnSync("plutil", ["-lint", path.join(root, "WorldDressCamera.xcodeproj", "project.pbxproj")], { encoding: "utf8" });
if (project.status !== 0) errors.push("invalid project.pbxproj");

console.log(JSON.stringify({
  swiftFiles: requiredSwift.length,
  resources: 2,
  infoPlist: plist.status === 0,
  xcodeProject: project.status === 0,
  errors
}, null, 2));
process.exit(errors.length ? 1 : 0);
