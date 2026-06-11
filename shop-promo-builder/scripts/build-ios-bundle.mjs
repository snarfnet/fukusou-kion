import { mkdir, rm, writeFile } from "node:fs/promises";
import { build } from "esbuild";

const outdir = "ios-dist";

await rm(outdir, { recursive: true, force: true });
await mkdir(outdir, { recursive: true });

await build({
  entryPoints: ["src/main.jsx"],
  bundle: true,
  format: "iife",
  platform: "browser",
  target: ["ios17"],
  outdir,
  entryNames: "main-ios",
  assetNames: "[name]-[hash]",
  loader: {
    ".png": "file",
  },
  define: {
    "process.env.NODE_ENV": "\"production\"",
  },
  minify: true,
});

await writeFile(
  `${outdir}/index.html`,
  `<!doctype html>
<html lang="ja">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover" />
    <meta name="theme-color" content="#1f5b45" />
    <title>小さなお店の宣伝ツール</title>
    <link rel="stylesheet" href="./main-ios.css" />
    <script defer src="./main-ios.js"></script>
  </head>
  <body>
    <div id="root"></div>
    <noscript>JavaScriptを有効にしてください。</noscript>
  </body>
</html>
`,
  "utf8",
);
