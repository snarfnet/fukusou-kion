import fs from "node:fs/promises";
import path from "node:path";
import QRCode from "qrcode";

const root = process.cwd();
const sourcePath = process.argv[2]
  ? path.resolve(root, process.argv[2])
  : path.resolve(root, "public/firebase-shop-data.example.json");
const outDir = path.resolve(root, "firebase-hosting");
const firebaseRcPath = path.resolve(root, ".firebaserc");

async function detectFirebasePublicUrl() {
  if (process.env.FIREBASE_PUBLIC_URL) return process.env.FIREBASE_PUBLIC_URL;
  try {
    const firebaseRc = JSON.parse(await fs.readFile(firebaseRcPath, "utf8"));
    const projectId = firebaseRc?.projects?.default;
    if (projectId) return `https://${projectId}.web.app`;
  } catch {
    // The project can still be provided with FIREBASE_PUBLIC_URL.
  }
  return "https://your-firebase-project-id.web.app";
}

const fallbackImage =
  "data:image/svg+xml," +
  encodeURIComponent(
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 800"><rect width="1200" height="800" fill="#f7efe3"/><circle cx="260" cy="210" r="130" fill="#1f5b45" opacity=".18"/><circle cx="900" cy="520" r="210" fill="#d9704a" opacity=".22"/><path d="M180 600h840" stroke="#1f5b45" stroke-width="18" stroke-linecap="round"/><text x="120" y="390" font-family="sans-serif" font-size="88" font-weight="800" fill="#1f5b45">Shop Page</text></svg>`,
  );

const fallbackIcon =
  "data:image/svg+xml," +
  encodeURIComponent(
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><rect width="512" height="512" rx="112" fill="#1f5b45"/><path d="M145 230h222l-22 142H167l-22-142Z" fill="#fff"/><path d="M184 230c0-58 32-94 72-94s72 36 72 94" fill="none" stroke="#fff" stroke-width="30" stroke-linecap="round"/></svg>`,
  );

function escapeHtml(value = "") {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function safeSlug(value = "shop") {
  const slug = String(value)
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9-]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 64);
  return slug || `shop-${Date.now()}`;
}

function createManifest(store) {
  return {
    name: store.name,
    short_name: String(store.name || "Shop").slice(0, 12),
    start_url: "./",
    display: "standalone",
    theme_color: store.theme || "#1f5b45",
    background_color: "#fbfaf6",
    icons: [
      {
        src: "icon.svg",
        sizes: "512x512",
        type: "image/svg+xml",
        purpose: "any maskable",
      },
    ],
  };
}

function createShopHtml(store, publicUrl) {
  const theme = store.theme || "#1f5b45";
  const accent = store.accent || "#d9704a";
  const hero = store.hero || fallbackImage;
  const icon = store.icon || fallbackIcon;
  const enabled = store.enabledFeatures || {};
  const newsItems = enabled.news !== false
    ? (store.news || []).map((item) => `<li>${escapeHtml(item)}</li>`).join("")
    : "";
  const productItems = enabled.products !== false
    ? (store.productItems || []).map((item) => `<li>${escapeHtml(item)}</li>`).join("")
    : "";
  const coupon = enabled.coupon !== false && store.showCampaign !== false
    ? `<section class="coupon"><span>${escapeHtml(store.couponLimit || "")}</span><strong>${escapeHtml(store.coupon || "")}</strong></section>`
    : "";
  const reserve = enabled.reservation && store.reserveUrl
    ? `<a class="reserve" href="${escapeHtml(store.reserveUrl)}" rel="noopener">${escapeHtml(store.reservationLabel || "予約する")}</a>`
    : "";

  return `<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="theme-color" content="${escapeHtml(theme)}">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-title" content="${escapeHtml(store.name)}">
  <link rel="manifest" href="./manifest.webmanifest">
  <link rel="apple-touch-icon" href="${icon}">
  <title>${escapeHtml(store.name)}</title>
  <style>
    *{box-sizing:border-box}body{margin:0;background:#fbfaf6;color:#1e211d;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}.hero{min-height:48vh;padding:24px;display:flex;flex-direction:column;justify-content:flex-end;color:white;background:linear-gradient(180deg,rgba(0,0,0,.12),rgba(0,0,0,.62)),url("${hero}");background-size:cover;background-position:center}.app-icon{width:76px;height:76px;border-radius:22px;object-fit:cover;box-shadow:0 16px 36px rgba(0,0,0,.28)}h1{margin:16px 0 6px;font-size:34px;line-height:1.15;letter-spacing:0}main{max-width:720px;margin:auto;padding:22px}.lead{font-size:16px;line-height:1.8}.coupon,.panel{margin:18px 0;padding:18px;border:1px solid #eadfce;border-radius:12px;background:#fff}.coupon span{display:block;color:${accent};font-weight:800}.coupon strong{display:block;margin-top:6px;color:${theme};font-size:22px}.grid{display:grid;gap:14px;grid-template-columns:repeat(auto-fit,minmax(220px,1fr))}h2{margin:0 0 10px;color:${theme};font-size:18px}ul{margin:0;padding-left:20px;line-height:1.8}.reserve{display:inline-flex;min-height:44px;align-items:center;justify-content:center;margin-top:12px;padding:0 18px;border-radius:999px;color:white;background:${theme};font-weight:800;text-decoration:none}.meta{color:#626860;line-height:1.8}.footer{padding:18px 22px 28px;color:#73766f;text-align:center;font-size:12px}@media(max-width:520px){h1{font-size:28px}.hero{min-height:44vh}}
  </style>
</head>
<body>
  <section class="hero">
    <img class="app-icon" src="${icon}" alt="">
    <h1>${escapeHtml(store.name)}</h1>
    <p>${escapeHtml(store.subtitle || "")}</p>
  </section>
  <main>
    <p class="lead">${escapeHtml(store.description || "")}</p>
    ${coupon}
    <div class="grid">
      ${productItems ? `<section class="panel"><h2>${escapeHtml(store.productLabel || "メニュー")}</h2><ul>${productItems}</ul></section>` : ""}
      ${newsItems ? `<section class="panel"><h2>お知らせ</h2><ul>${newsItems}</ul></section>` : ""}
      <section class="panel">
        <h2>お店情報</h2>
        <p class="meta">${escapeHtml(store.hours || "")}<br>${escapeHtml(store.address || "")}<br>${escapeHtml(store.instagram || "")}</p>
        ${reserve}
      </section>
    </div>
  </main>
  <p class="footer">ホーム画面に追加すると、お店のアイコンからすぐ開けます。</p>
  <script type="application/ld+json">${JSON.stringify({
    "@context": "https://schema.org",
    "@type": "LocalBusiness",
    name: store.name,
    url: publicUrl,
    address: store.address,
  })}</script>
</body>
</html>`;
}

async function copyIfFileLikeDataUrl(dataUrl, outputPath) {
  if (!dataUrl || !String(dataUrl).startsWith("data:")) return false;
  const [, payload = ""] = String(dataUrl).split(",", 2);
  if (!payload) return false;
  await fs.writeFile(outputPath, Buffer.from(payload, "base64"));
  return true;
}

async function main() {
  const baseUrl = await detectFirebasePublicUrl();
  const raw = await fs.readFile(sourcePath, "utf8");
  const parsed = JSON.parse(raw);
  const stores = Array.isArray(parsed.stores) ? parsed.stores : [parsed];

  await fs.rm(outDir, { recursive: true, force: true });
  await fs.mkdir(outDir, { recursive: true });

  const links = [];
  for (const inputStore of stores) {
    const store = { ...inputStore, slug: safeSlug(inputStore.slug || inputStore.name) };
    const shopDir = path.join(outDir, "shops", store.slug);
    const publicUrl = `${baseUrl.replace(/\/$/, "")}/shops/${store.slug}`;
    await fs.mkdir(shopDir, { recursive: true });
    await fs.writeFile(path.join(shopDir, "index.html"), createShopHtml(store, publicUrl));
    await fs.writeFile(path.join(shopDir, "manifest.webmanifest"), JSON.stringify(createManifest(store), null, 2));
    await fs.writeFile(path.join(shopDir, "qr.png"), await QRCode.toBuffer(publicUrl, { width: 720, margin: 1 }));

    const iconPath = path.join(shopDir, "icon.svg");
    if (!(await copyIfFileLikeDataUrl(store.icon, iconPath))) {
      await fs.writeFile(iconPath, decodeURIComponent(fallbackIcon.replace("data:image/svg+xml,", "")));
    }
    links.push({ name: store.name, slug: store.slug, url: publicUrl });
  }

  const indexHtml = `<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>小さなお店の宣伝ツール 公開ページ一覧</title>
  <style>body{margin:0;padding:32px;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;background:#fbfaf6;color:#20231f}main{max-width:760px;margin:auto}.card{display:block;margin:12px 0;padding:18px;border:1px solid #eadfce;border-radius:10px;background:white;color:#1f5b45;text-decoration:none}.card strong{display:block;font-size:18px}.card span{display:block;margin-top:6px;color:#626860;overflow-wrap:anywhere}</style>
</head>
<body>
  <main>
    <h1>公開ページ一覧</h1>
    <p>Firebase Hostingへ公開する静的なお店ページです。</p>
    ${links.map((link) => `<a class="card" href="./shops/${escapeHtml(link.slug)}/"><strong>${escapeHtml(link.name)}</strong><span>${escapeHtml(link.url)}</span></a>`).join("")}
  </main>
</body>
</html>`;
  await fs.writeFile(path.join(outDir, "index.html"), indexHtml);
  await fs.writeFile(path.join(outDir, "publish-links.json"), JSON.stringify(links, null, 2));

  console.log(`Firebase Hosting files created: ${path.relative(root, outDir)}`);
  for (const link of links) {
    console.log(`${link.name}: ${link.url}`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
