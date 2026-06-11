import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
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

const css = await readFile(`${outdir}/main-ios.css`, "utf8");
const js = await readFile(`${outdir}/main-ios.js`, "utf8");

await writeFile(
  `${outdir}/index.html`,
  `<!doctype html>
<html lang="ja">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover" />
    <meta name="theme-color" content="#1f5b45" />
    <title>小さなお店の宣伝ツール</title>
    <style>
${css}
    </style>
    <script>
      window.addEventListener("error", function (event) {
        if (event.target !== window) return;
        var root = document.getElementById("root");
        if (!root) return;
        root.innerHTML = '<main style="font-family:-apple-system;padding:24px;background:#fbfaf6;color:#14231b;min-height:100vh;"><h1 style="font-size:22px;">画面を表示できませんでした</h1><p style="line-height:1.7;">JavaScriptの起動でエラーが起きました。</p><pre style="white-space:pre-wrap;background:#fff;padding:14px;border-radius:8px;">' + String(event.message || "JavaScript error").replace(/[&<>]/g, function (c) { return { "&": "&amp;", "<": "&lt;", ">": "&gt;" }[c]; }) + '</pre></main>';
      });
    </script>
  </head>
  <body>
    <div id="root">
      <main style="font-family:-apple-system;padding:24px;background:#fbfaf6;color:#14231b;min-height:100vh;">
        <h1 style="font-size:22px;">小さなお店の宣伝ツール</h1>
        <p style="line-height:1.7;">起動しています...</p>
      </main>
    </div>
    <noscript>JavaScriptを有効にしてください。</noscript>
    <script>
${js}
    </script>
  </body>
</html>
`,
  "utf8",
);
