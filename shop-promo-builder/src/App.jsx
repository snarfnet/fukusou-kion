import { useEffect, useMemo, useState } from "react";
import QRCode from "qrcode";
import heroImage from "./assets/cafe-hero.png";
import campaignImage from "./assets/campaign-banner.png";
import appIcon from "./assets/app-icon.png";
import zakkaHero from "./assets/zakka-hero.png";
import zakkaCampaign from "./assets/zakka-campaign.png";
import zakkaIcon from "./assets/zakka-icon.png";
import hairHero from "./assets/hair-hero.png";
import hairCampaign from "./assets/hair-campaign.png";
import hairIcon from "./assets/hair-icon.png";
import nailHero from "./assets/nail-hero.png";
import nailCampaign from "./assets/nail-campaign.png";
import nailIcon from "./assets/nail-icon.png";
import gymHero from "./assets/gym-hero.png";
import gymCampaign from "./assets/gym-campaign.png";
import gymIcon from "./assets/gym-icon.png";

const STORAGE_KEY = "shop-promo-builder.store.v2";

const tabs = ["基本設定", "トップ画面", "表示機能", "リンク", "公開設定"];

const navItems = [
  ["fa-gauge-high", "ダッシュボード"],
  ["fa-store", "基本情報"],
  ["fa-palette", "デザイン設定"],
  ["fa-ticket", "クーポン管理"],
  ["fa-sliders", "表示機能"],
  ["fa-bell", "お知らせ"],
  ["fa-download", "インストール促進"],
];

const featureOptions = [
  { key: "news", icon: "fa-bell", label: "お知らせ", shortLabel: "お知らせ" },
  { key: "products", icon: "fa-bag-shopping", label: "商品・メニュー", shortLabel: "商品" },
  { key: "reservation", icon: "fa-calendar-check", label: "予約", shortLabel: "予約" },
  { key: "coupon", icon: "fa-ticket", label: "クーポン", shortLabel: "クーポン" },
  { key: "stamp", icon: "fa-face-smile", label: "スタンプ", shortLabel: "スタンプ" },
  { key: "access", icon: "fa-location-dot", label: "アクセス", shortLabel: "アクセス" },
];

const paidAddOns = [
  {
    icon: "fa-file-lines",
    title: "A4チラシ作成",
    description: "アプリ内のメニューやお知らせから印刷用チラシを作成します。",
    status: "実装中",
  },
  {
    icon: "fa-bullhorn",
    title: "一斉通知",
    description: "新着情報やクーポンを登録客へ送ります。公開サーバーと通知APIが必要です。",
    status: "API連携予定",
  },
  {
    icon: "fa-desktop",
    title: "macOS展開",
    description: "Macでも管理画面が動作します。",
    status: "別ビルド予定",
  },
];

const storeSamples = {
  cafe: {
    label: "カフェ",
    name: "カフェこもれび",
    slug: "komorebi-cafe",
    subtitle: "自家焙煎コーヒーと手作りスイーツ",
    description:
      "木漏れ日のようにやさしい時間が流れる小さなカフェです。自家焙煎のコーヒーと、季節の素材で作るスイーツを用意しています。",
    theme: "#1f5b45",
    accent: "#d4a64a",
    hours: "10:00 - 18:00 / 火曜休み",
    address: "東京都杉並区こもれび町1-2-3",
    reserveUrl: "",
    instagram: "@komorebi_cafe",
    productLabel: "季節のおすすめ",
    productNavLabel: "商品",
    reservationLabel: "予約する",
    coupon: "季節のスイーツセット 10% OFF",
    couponLimit: "6/30(日)まで",
    showCampaign: true,
    news: ["新作スイーツ「抹茶のチーズケーキ」登場", "雨の日限定でドリンク50円引き", "週末は焼き菓子ギフトを多めにご用意します"],
    productItems: ["季節のスイーツ", "焼き菓子ギフト"],
    hero: heroImage,
    campaign: campaignImage,
    icon: appIcon,
    enabledFeatures: { news: true, products: true, reservation: false, coupon: true, stamp: true, access: true },
  },
  zakka: {
    label: "雑貨屋",
    name: "雑貨屋みぃ屋",
    slug: "miiya-zakka",
    subtitle: "暮らしを少し楽しくする小物とギフト",
    description:
      "雑貨屋みぃ屋は、手仕事の小物、季節の飾り、ちょっとした贈り物を集めた小さなお店です。新入荷や週末限定セットをアプリでお知らせします。",
    theme: "#7b4f37",
    accent: "#d88c5f",
    hours: "11:00 - 19:00 / 水曜休み",
    address: "大阪府大阪市みぃ屋通り2-8-1",
    reserveUrl: "",
    instagram: "@miiya_zakka",
    productLabel: "新入荷の雑貨",
    productNavLabel: "商品",
    reservationLabel: "取り置き相談",
    coupon: "ギフトラッピング無料",
    couponLimit: "今月末まで",
    showCampaign: true,
    news: ["春色のポーチとハンカチが入荷しました", "ギフトラッピング無料キャンペーン中", "週末限定で小さな蚤の市コーナーを開きます"],
    productItems: ["季節の小物", "ギフトセット"],
    hero: zakkaHero,
    campaign: zakkaCampaign,
    icon: zakkaIcon,
    enabledFeatures: { news: true, products: true, reservation: false, coupon: true, stamp: false, access: true },
  },
  salon: {
    label: "美容室",
    name: "美容室こもれび",
    slug: "komorebi-hair",
    subtitle: "静かな席で整える大人のヘアサロン",
    description:
      "美容室こもれびは、落ち着いた空間でカット、カラー、ヘッドスパを受けられる予約制サロンです。空き枠や季節メニューをアプリで案内します。",
    theme: "#243f3a",
    accent: "#c9a46a",
    hours: "9:30 - 18:30 / 月曜休み",
    address: "東京都世田谷区こもれび坂4-5-6",
    reserveUrl: "https://example.com/hair-reserve",
    instagram: "@komorebi_hair",
    productLabel: "人気メニュー",
    productNavLabel: "メニュー",
    reservationLabel: "予約する",
    coupon: "初回ヘッドスパ 20% OFF",
    couponLimit: "初回来店限定",
    showCampaign: true,
    news: ["梅雨前のまとまりケアメニューを始めました", "平日午前の予約枠に空きがあります", "初回ヘッドスパ割引を実施中です"],
    productItems: ["カット・カラー", "ヘッドスパ"],
    hero: hairHero,
    campaign: hairCampaign,
    icon: hairIcon,
    enabledFeatures: { news: true, products: true, reservation: true, coupon: true, stamp: false, access: true },
  },
  nail: {
    label: "ネイルサロン",
    name: "ネイルサロン ルーチェ",
    slug: "luce-nail",
    subtitle: "手元に小さな光を添えるネイルサロン",
    description:
      "ルーチェは、日常になじむ上品なネイルから季節のアートまで相談できる小さなネイルサロンです。デザイン例、空き枠、限定クーポンをまとめて見られます。",
    theme: "#8a5263",
    accent: "#d8b16d",
    hours: "10:00 - 20:00 / 不定休",
    address: "神奈川県横浜市花町3-12",
    reserveUrl: "https://example.com/nail-reserve",
    instagram: "@luce_nail",
    productLabel: "今月のデザイン",
    productNavLabel: "メニュー",
    reservationLabel: "予約する",
    coupon: "オフ無料キャンペーン",
    couponLimit: "平日限定",
    showCampaign: true,
    news: ["今月の定額デザインを追加しました", "平日夕方の予約枠に空きがあります", "ハンドケア付きメニューを開始しました"],
    productItems: ["定額デザイン", "ハンドケア"],
    hero: nailHero,
    campaign: nailCampaign,
    icon: nailIcon,
    enabledFeatures: { news: true, products: true, reservation: true, coupon: true, stamp: true, access: true },
  },
  gym: {
    label: "パーソナルジム",
    name: "ジム ステディ",
    slug: "steady-gym",
    subtitle: "週2回から続ける小さなパーソナルジム",
    description:
      "ジム ステディは、初心者でも続けやすい予約制のパーソナルジムです。体験予約、トレーニングメニュー、入会キャンペーンをアプリから確認できます。",
    theme: "#263238",
    accent: "#83b547",
    hours: "7:00 - 22:00 / 日曜休み",
    address: "東京都渋谷区ステディ町5-10",
    reserveUrl: "https://example.com/gym-trial",
    instagram: "@steady_gym",
    productLabel: "トレーニングプラン",
    productNavLabel: "プラン",
    reservationLabel: "体験予約",
    coupon: "初回体験 1,000円",
    couponLimit: "先着20名まで",
    showCampaign: true,
    news: ["初回体験の受付枠を追加しました", "夏前の短期集中プランを開始しました", "朝7時台の予約が取りやすくなっています"],
    productItems: ["週2回プラン", "短期集中プラン"],
    hero: gymHero,
    campaign: gymCampaign,
    icon: gymIcon,
    enabledFeatures: { news: true, products: true, reservation: true, coupon: true, stamp: false, access: true },
  },
};

const sampleNews = [
  "新作スイーツ「抹茶のチーズケーキ」登場",
  "雨の日限定でドリンク50円引き",
  "週末は焼き菓子ギフトを多めにご用意します",
];

const defaultStore = {
  name: "カフェこもれび",
  slug: "komorebi-cafe",
  subtitle: "自家焙煎コーヒーと手作りスイーツ",
  description:
    "木漏れ日のようにやさしい時間が流れる小さなカフェです。自家焙煎のコーヒーと、季節の素材で作るスイーツを用意しています。",
  theme: "#1f5b45",
  accent: "#d4a64a",
  phone: "03-1234-5678",
  hours: "10:00 - 18:00 / 火曜休み",
  address: "東京都杉並区こもれび町1-2-3",
  reserveUrl: "https://example.com/reserve",
  instagram: "@komorebi_cafe",
  shopType: "cafe",
  productLabel: "季節のおすすめ",
  productNavLabel: "商品",
  reservationLabel: "予約する",
  coupon: "季節のスイーツセット 10% OFF",
  couponLimit: "6/30(日)まで",
  showCampaign: true,
  news: storeSamples.cafe.news,
  productItems: storeSamples.cafe.productItems,
  enabledFeatures: storeSamples.cafe.enabledFeatures,
  publish: true,
  hero: heroImage,
  campaign: campaignImage,
  icon: appIcon,
};

function loadStoredStore() {
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (!saved) return defaultStore;
    const parsed = JSON.parse(saved);
    return {
      ...defaultStore,
      ...parsed,
      enabledFeatures: {
        ...defaultStore.enabledFeatures,
        ...(parsed.enabledFeatures || {}),
      },
    };
  } catch {
    return defaultStore;
  }
}

function normalizeSlug(value) {
  return value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9-]+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 40);
}

function resizeImage(file, options) {
  const { maxWidth, maxHeight, mimeType = "image/jpeg", quality = 0.86, square = false } = options;

  return new Promise((resolve, reject) => {
    if (!file) return;

    const reader = new FileReader();
    reader.onerror = reject;
    reader.onload = () => {
      const image = new Image();
      image.onerror = reject;
      image.onload = () => {
        let sourceX = 0;
        let sourceY = 0;
        let sourceWidth = image.width;
        let sourceHeight = image.height;

        if (square) {
          const side = Math.min(image.width, image.height);
          sourceX = Math.round((image.width - side) / 2);
          sourceY = Math.round((image.height - side) / 2);
          sourceWidth = side;
          sourceHeight = side;
        }

        const scale = Math.min(maxWidth / sourceWidth, maxHeight / sourceHeight, 1);
        const width = Math.round(sourceWidth * scale);
        const height = Math.round(sourceHeight * scale);
        const canvas = document.createElement("canvas");
        canvas.width = width;
        canvas.height = height;
        const context = canvas.getContext("2d");
        context.drawImage(image, sourceX, sourceY, sourceWidth, sourceHeight, 0, 0, width, height);

        resolve({
          dataUrl: canvas.toDataURL(mimeType, quality),
          width,
          height,
          originalWidth: image.width,
          originalHeight: image.height,
        });
      };
      image.src = reader.result;
    };
    reader.readAsDataURL(file);
  });
}

export function App() {
  const isLandingRoute = window.location.pathname.startsWith("/landing");
  const isCustomerRoute = window.location.pathname.startsWith("/shop/");
  const [activeTab, setActiveTab] = useState(tabs[0]);
  const [store, setStore] = useState(loadStoredStore);
  const [qrCode, setQrCode] = useState("");
  const [saveStatus, setSaveStatus] = useState("未保存");
  const [imageStatus, setImageStatus] = useState("");
  const [notificationStatus, setNotificationStatus] = useState("未設定");

  const publicUrl = useMemo(() => {
    const slug = store.slug || "komorebi-cafe";
    return `${window.location.origin}/shop/${slug}`;
  }, [store.slug]);

  const manifestPreview = useMemo(
    () => ({
      name: store.name,
      short_name: store.name.slice(0, 12),
      start_url: `/shop/${store.slug}`,
      display: "standalone",
      theme_color: store.theme,
      background_color: "#fbfaf6",
      icons: [{ src: "/app-icon.png", sizes: "1024x1024", type: "image/png" }],
    }),
    [store.name, store.slug, store.theme],
  );

  useEffect(() => {
    QRCode.toDataURL(publicUrl, {
      width: 240,
      margin: 1,
      color: { dark: "#111714", light: "#ffffff" },
    }).then(setQrCode);
  }, [publicUrl]);

  useEffect(() => {
    document.title = isCustomerRoute ? store.name : "小さなお店の宣伝ツール";
    const themeMeta = document.querySelector('meta[name="theme-color"]');
    themeMeta?.setAttribute("content", isLandingRoute ? "#213f35" : store.theme);
    const appleTitle = document.querySelector('meta[name="apple-mobile-web-app-title"]');
    appleTitle?.setAttribute("content", isCustomerRoute ? store.name : "小さなお店の宣伝ツール");
  }, [isCustomerRoute, isLandingRoute, store.name, store.theme]);

  useEffect(() => {
    if ("serviceWorker" in navigator) {
      navigator.serviceWorker.register("/sw.js").catch(() => {});
    }
  }, []);

  function updateField(key, value) {
    setStore((current) => ({ ...current, [key]: value }));
    setSaveStatus("未保存の変更あり");
  }

  function updateShopType(shopType) {
    const sample = storeSamples[shopType];
    if (!sample) return;
    setStore((current) => ({
      ...current,
      shopType,
      name: sample.name,
      slug: sample.slug,
      subtitle: sample.subtitle,
      description: sample.description,
      theme: sample.theme,
      accent: sample.accent,
      hours: sample.hours,
      address: sample.address,
      reserveUrl: sample.reserveUrl,
      instagram: sample.instagram,
      productLabel: sample.productLabel,
      productNavLabel: sample.productNavLabel,
      reservationLabel: sample.reservationLabel,
      coupon: sample.coupon,
      couponLimit: sample.couponLimit,
      showCampaign: sample.showCampaign,
      news: sample.news,
      productItems: sample.productItems,
      hero: sample.hero,
      campaign: sample.campaign,
      icon: sample.icon,
      enabledFeatures: {
        ...sample.enabledFeatures,
      },
    }));
    setSaveStatus("未保存の変更あり");
  }

  function updateFeature(key, value) {
    setStore((current) => ({
      ...current,
      enabledFeatures: {
        ...current.enabledFeatures,
        [key]: value,
      },
    }));
    setSaveStatus("未保存の変更あり");
  }

  function saveSettings() {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(store));
    setSaveStatus("保存しました");
  }

  function resetSettings() {
    localStorage.removeItem(STORAGE_KEY);
    setStore(defaultStore);
    setSaveStatus("初期データに戻しました");
  }

  async function handleImage(file, key, options) {
    if (!file) return;
    setImageStatus("画像をリサイズ中...");
    const result = await resizeImage(file, options);
    updateField(key, result.dataUrl);
    setImageStatus(`${file.name} を ${result.width} x ${result.height}px に調整しました`);
  }


  async function requestNotification() {
    if (!("Notification" in window) || !("serviceWorker" in navigator)) {
      setNotificationStatus("この環境では通知に対応していません");
      return;
    }
    const permission = await Notification.requestPermission();
    if (permission !== "granted") {
      setNotificationStatus("通知が許可されていません");
      return;
    }
    const registration = await navigator.serviceWorker.ready;
    registration.showNotification(`${store.name}からのお知らせ`, {
      body: store.news?.[0] || store.coupon || "新しいお知らせがあります。",
      icon: store.icon,
      badge: store.icon,
      data: { url: window.location.href },
    });
    setNotificationStatus("テスト通知を送信しました");
  }

  function openCustomerApp() {
    window.open(publicUrl, "_blank", "noopener,noreferrer");
  }


  function openFlyer() {
    const campaignMarkup = store.enabledFeatures.coupon && store.showCampaign
      ? `<section class="flyer-campaign"><img src="${store.campaign}" alt=""><div><strong>${store.coupon}</strong><span>${store.couponLimit}</span></div></section>`
      : "";
    const productMarkup = store.enabledFeatures.products
      ? `<section><h2>${store.productLabel}</h2><div class="flyer-menu"><p>${store.productItems?.[0] || store.productLabel}</p><p>${store.productItems?.[1] || "おすすめ"}</p></div></section>`
      : "";
    const reserveMarkup = store.enabledFeatures.reservation
      ? `<a class="flyer-reserve" href="${store.reserveUrl}">${store.reservationLabel}</a>`
      : "";
    const newsMarkup = (store.news || []).map((news) => `<li>${news}</li>`).join("");
    const html = `<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${store.name} A4チラシ</title>
  <style>
    @page{size:A4;margin:0}*{box-sizing:border-box}body{margin:0;background:#ddd;font-family:sans-serif;color:#20231f}.page{width:210mm;min-height:297mm;margin:auto;background:#fbfaf6;padding:16mm;position:relative;overflow:hidden}.hero{height:86mm;border-radius:8px;background:linear-gradient(180deg,rgba(0,0,0,.05),rgba(0,0,0,.5)),url('${store.hero}');background-size:cover;background-position:center;color:white;padding:12mm 12mm 14mm;display:flex;flex-direction:column;justify-content:flex-end}.hero p{margin:3mm 0 0;line-height:1.45}.icon{width:24mm;height:24mm;border-radius:7mm;object-fit:cover;margin-bottom:7mm;box-shadow:0 8px 20px #0005}h1{font-size:28pt;line-height:1.15;margin:0}h2{font-size:15pt;margin:10mm 0 4mm;color:${store.theme}}.lead{font-size:12pt;line-height:1.8}.flyer-campaign{display:grid;grid-template-columns:1.2fr .8fr;gap:6mm;margin:8mm 0;padding:5mm;border:1px solid #e6dfd2;border-radius:6px;background:white}.flyer-campaign img{width:100%;height:34mm;object-fit:cover;border-radius:4px}.flyer-campaign strong{display:block;font-size:17pt;color:${store.theme}}.flyer-campaign span{display:block;margin-top:3mm;color:${store.accent};font-weight:700}.flyer-menu{display:grid;grid-template-columns:1fr 1fr;gap:4mm}.flyer-menu p{margin:0;padding:5mm;border:1px solid #e6dfd2;background:white;font-weight:700}.info{display:grid;grid-template-columns:1fr 1fr;gap:6mm;margin-top:8mm}.news{line-height:1.8}.flyer-reserve{display:inline-block;margin-top:6mm;padding:4mm 8mm;border-radius:999px;background:${store.theme};color:white;text-decoration:none;font-weight:700}.footer{position:absolute;left:16mm;right:16mm;bottom:12mm;border-top:1px solid #ded7cc;padding-top:5mm;font-size:10pt;color:#555}@media print{body{background:white}.page{margin:0}}
  </style>
</head>
<body>
  <main class="page">
    <section class="hero"><img class="icon" src="${store.icon}" alt=""><h1>${store.name}</h1><p>${store.subtitle}</p></section>
    <p class="lead">${store.description}</p>
    ${campaignMarkup}
    ${productMarkup}
    <section class="info"><div><h2>お知らせ</h2><ul class="news">${newsMarkup}</ul></div><div><h2>店舗情報</h2><p>${store.hours}<br>${store.address}<br>${store.instagram}</p>${reserveMarkup}</div></section>
    <p class="footer">このチラシは小さなお店の宣伝ツールから作成しました。QRコードや地図リンクは公開版で追加できます。</p>
  </main>
</body>
</html>`;
    const blob = new Blob([html], { type: "text/html" });
    const url = URL.createObjectURL(blob);
    window.open(url, "_blank");
    window.setTimeout(() => URL.revokeObjectURL(url), 60000);
  }

  function exportHtml() {
    const html = `<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="theme-color" content="${store.theme}">
  <link rel="apple-touch-icon" href="${store.icon}">
  <title>${store.name}</title>
  <style>
    body{margin:0;font-family:sans-serif;background:#fbfaf6;color:#20231f}
    .hero{min-height:44vh;background:linear-gradient(180deg,rgba(0,0,0,.18),rgba(0,0,0,.55)),url('${store.hero}');background-size:cover;background-position:center;color:white;padding:28px}
    .icon{width:72px;height:72px;border-radius:20px;object-fit:cover;box-shadow:0 12px 28px #0004}
    main{padding:24px;max-width:680px;margin:auto}.coupon{border:1px solid #e8dfce;border-radius:16px;padding:18px;background:white}
    a{color:${store.theme};font-weight:700}
  </style>
</head>
<body>
  <section class="hero"><img class="icon" src="${store.icon}" alt=""><h1>${store.name}</h1><p>${store.subtitle}</p></section>
  <main><p>${store.description}</p>${store.enabledFeatures.coupon ? `<section class="coupon"><h2>${store.coupon}</h2><p>${store.couponLimit}</p></section>` : ""}<p>${store.hours}</p><p>${store.address}</p>${store.enabledFeatures.reservation ? `<a href="${store.reserveUrl}">${store.reservationLabel}</a>` : ""}</main>
</body>
</html>`;
    const blob = new Blob([html], { type: "text/html" });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = `${store.slug || "shop"}-customer-app.html`;
    anchor.click();
    URL.revokeObjectURL(url);
  }

  if (isLandingRoute) {
    return <MarketingSite />;
  }

  if (isCustomerRoute) {
    return (
      <main className="customer-shell" style={{ "--theme": store.theme, "--accent": store.accent }}>
        <PhonePreview store={store} customerOnly />
        <section className="customer-install">
          <img src={store.icon} alt="" />
          <div>
            <h1>{store.name}</h1>
            <p>このページは店ごとの公開URLです。Safariで開いてホーム画面に追加すると、お店専用アプリのように使えます。</p>
            <button className="primary-button inline" onClick={requestNotification}>
              通知を受け取る
            </button>
            <small>{notificationStatus}</small>
          </div>
        </section>
      </main>
    );
  }

  return (
    <main className="shell" style={{ "--theme": store.theme, "--accent": store.accent }}>
      <aside className="sidebar">
        <div className="brand">
          <img src={store.icon} alt="" />
          <div>
            <strong>小さなお店の宣伝ツール</strong>
            <span>アプリ作成・管理</span>
          </div>
        </div>

        <nav>
          {navItems.map(([icon, label], index) => (
            <button className={index === 2 ? "nav-active" : ""} key={label}>
              <i className={`fa-solid ${icon}`} aria-hidden="true" />
              {label}
            </button>
          ))}
        </nav>

        <section className="publish-box">
          <p>
            <span className={store.publish ? "dot on" : "dot"} />
            {store.publish ? "アプリ公開中" : "下書き"}
          </p>
          <small>状態：{saveStatus}</small>
          <button className="ghost-button" onClick={openCustomerApp}>
            公開URLを開く
            <i className="fa-solid fa-arrow-up-right-from-square" aria-hidden="true" />
          </button>
          <button className="ghost-button" onClick={saveSettings}>
            設定を保存する
          </button>
          <button className="ghost-button" onClick={openFlyer}>
            A4チラシを作る
            <i className="fa-solid fa-print" aria-hidden="true" />
          </button>
          <button className="primary-button" onClick={exportHtml}>
            HTMLを書き出す
          </button>
        </section>
      </aside>

      <section className="workspace">
        <header className="topbar">
          <div>
            <h1>デザイン設定</h1>
            <p>編集した内容を保存し、店ごとの公開URLと実QRコードを作れます。</p>
          </div>
          <div className="top-actions">
            <button title="ヘルプ">
              <i className="fa-regular fa-circle-question" aria-hidden="true" />
            </button>
            <button title="通知">
              <i className="fa-regular fa-bell" aria-hidden="true" />
              <span>3</span>
            </button>
            <strong>{store.name}</strong>
          </div>
        </header>

        <div className="tabs" role="tablist" aria-label="設定カテゴリ">
          {tabs.map((tab) => (
            <button className={tab === activeTab ? "tab-active" : ""} key={tab} onClick={() => setActiveTab(tab)}>
              {tab}
            </button>
          ))}
        </div>

        <div className="editor">
          <FormRow label="ショップ名" count={`${store.name.length}/20`}>
            <input value={store.name} maxLength={20} onChange={(event) => updateField("name", event.target.value)} />
          </FormRow>

          <FormRow label="公開URL">
            <div className="slug-row">
              <span>{window.location.origin}/shop/</span>
              <input value={store.slug} onChange={(event) => updateField("slug", normalizeSlug(event.target.value))} />
            </div>
          </FormRow>

          <FormRow label="店舗サンプル">
            <div className="preset-row">
              {Object.entries(storeSamples).map(([key, preset]) => (
                <button
                  className={store.shopType === key ? "preset-active" : ""}
                  key={key}
                  onClick={(event) => {
                    event.preventDefault();
                    updateShopType(key);
                  }}
                >
                  {preset.label}
                </button>
              ))}
            </div>
          </FormRow>

          <FormRow label="サブタイトル" count={`${store.subtitle.length}/32`}>
            <input value={store.subtitle} maxLength={32} onChange={(event) => updateField("subtitle", event.target.value)} />
          </FormRow>

          <FormRow label="アプリアイコン">
            <div className="asset-row">
              <img className="icon-preview" src={store.icon} alt="現在のアプリアイコン" />
              <div className="asset-actions">
                <label className="upload-button">
                  <i className="fa-solid fa-upload" aria-hidden="true" />
                  画像を変更
                  <input
                    type="file"
                    accept="image/*"
                    onChange={(event) =>
                      handleImage(event.target.files?.[0], "icon", {
                        maxWidth: 1024,
                        maxHeight: 1024,
                        mimeType: "image/png",
                        quality: 0.95,
                        square: true,
                      })
                    }
                  />
                </label>
                <small>アップロード時に 1024 x 1024px へ自動調整します。</small>
              </div>
            </div>
          </FormRow>

          <FormRow label="テーマカラー">
            <ColorControl value={store.theme} onChange={(value) => updateField("theme", value)} />
          </FormRow>
          <FormRow label="アクセントカラー">
            <ColorControl value={store.accent} onChange={(value) => updateField("accent", value)} />
          </FormRow>

          <FormRow label="ヒーロー画像">
            <ImageUpload
              image={store.hero}
              onChange={(file) =>
                handleImage(file, "hero", { maxWidth: 1200, maxHeight: 600, mimeType: "image/jpeg", quality: 0.84 })
              }
              note="アップロード時に最大 1200 x 600px へ調整します。"
            />
          </FormRow>

          <FormRow label="キャンペーン画像">
            <div className="campaign-setting">
              <label className="feature-toggle compact">
                <input
                  type="checkbox"
                  checked={Boolean(store.showCampaign)}
                  onChange={(event) => updateField("showCampaign", event.target.checked)}
                />
                <span>
                  <i className="fa-solid fa-image" aria-hidden="true" />
                  キャンペーン画像を表示
                </span>
              </label>
              {store.showCampaign && (
                <ImageUpload
                  image={store.campaign}
                  onChange={(file) =>
                    handleImage(file, "campaign", { maxWidth: 1200, maxHeight: 400, mimeType: "image/jpeg", quality: 0.84 })
                  }
                  note="アップロード時に最大 1200 x 400px へ調整します。"
                />
              )}
            </div>
          </FormRow>

          {imageStatus && <p className="save-status">{imageStatus}</p>}

          <FormRow label="表示する機能">
            <div className="feature-grid">
              {featureOptions.map((feature) => (
                <label className="feature-toggle" key={feature.key}>
                  <input
                    type="checkbox"
                    checked={Boolean(store.enabledFeatures[feature.key])}
                    onChange={(event) => updateFeature(feature.key, event.target.checked)}
                  />
                  <span>
                    <i className={`fa-solid ${feature.icon}`} aria-hidden="true" />
                    {feature.label}
                  </span>
                </label>
              ))}
            </div>
          </FormRow>

          <FormRow label="リンク・表示名">
            <div className="two-col">
              <input value={store.productLabel} onChange={(event) => updateField("productLabel", event.target.value)} />
              <input value={store.productNavLabel} onChange={(event) => updateField("productNavLabel", event.target.value)} />
              <input value={store.reservationLabel} onChange={(event) => updateField("reservationLabel", event.target.value)} />
              <input value={store.reserveUrl} onChange={(event) => updateField("reserveUrl", event.target.value)} />
              <input value={store.instagram} onChange={(event) => updateField("instagram", event.target.value)} />
            </div>
          </FormRow>

          <FormRow label="クーポン">
            <div className="two-col">
              <input value={store.coupon} onChange={(event) => updateField("coupon", event.target.value)} />
              <input value={store.couponLimit} onChange={(event) => updateField("couponLimit", event.target.value)} />
            </div>
          </FormRow>

          <FormRow label="ショップ紹介文" count={`${store.description.length}/200`}>
            <textarea value={store.description} maxLength={200} onChange={(event) => updateField("description", event.target.value)} />
          </FormRow>

          <FormRow label="営業時間・住所">
            <div className="two-col">
              <input value={store.hours} onChange={(event) => updateField("hours", event.target.value)} />
              <input value={store.address} onChange={(event) => updateField("address", event.target.value)} />
            </div>
          </FormRow>

          <div className="editor-actions">
            <button className="primary-button inline" onClick={saveSettings}>
              設定を保存する
            </button>
            <button className="ghost-button inline" onClick={resetSettings}>
              初期データに戻す
            </button>
            <span>{saveStatus}</span>
          </div>
        </div>
      </section>

      <aside className="preview-pane">
        <div className="preview-header">
          <div>
            <h2>アプリプレビュー</h2>
            <p>ライブプレビュー</p>
          </div>
          <button onClick={openCustomerApp}>
            <i className="fa-solid fa-arrow-up-right-from-square" aria-hidden="true" />
            公開URL
          </button>
        </div>
        <PhonePreview store={store} />
        <section className="install-box">
          <h3>インストール用QRコード</h3>
          <p>このQRコードは公開URLから実生成しています。</p>
          <div className="qr-row">
            {qrCode && <img className="qr-image" src={qrCode} alt="公開URLのQRコード" />}
            <code>{publicUrl}</code>
          </div>
          <a className="download-link" href={qrCode} download={`${store.slug || "shop"}-qr.png`}>
            QRコードをダウンロード
          </a>
          <pre>{JSON.stringify(manifestPreview, null, 2)}</pre>
        </section>

        <section className="addon-box">
          <div className="addon-head">
            <h3>別課金オプション</h3>
            <span>3セット</span>
          </div>
          <div className="addon-list">
            {paidAddOns.map((addon) => (
              <article key={addon.title}>
                <i className={`fa-solid ${addon.icon}`} aria-hidden="true" />
                <div>
                  <strong>{addon.title}</strong>
                  <p>{addon.description}</p>
                </div>
                <em>{addon.status}</em>
              </article>
            ))}
          </div>
        </section>
      </aside>
    </main>
  );
}

function FormRow({ label, count, children }) {
  return (
    <label className="form-row">
      <span>
        {label}
        {count && <small>{count}</small>}
      </span>
      <div>{children}</div>
    </label>
  );
}

function ColorControl({ value, onChange }) {
  const swatches = ["#1f5b45", "#f4efe6", "#d4a64a", "#8d7b6d", "#242729", "#d99a8e", "#9fb8be", "#a7a1b6"];
  return (
    <div className="color-control">
      <div className="swatches">
        {swatches.map((color) => (
          <button
            key={color}
            className={value === color ? "swatch selected" : "swatch"}
            style={{ backgroundColor: color }}
            onClick={(event) => {
              event.preventDefault();
              onChange(color);
            }}
            title={color}
          />
        ))}
      </div>
      <input type="color" value={value} onChange={(event) => onChange(event.target.value)} />
      <input value={value.toUpperCase()} onChange={(event) => onChange(event.target.value)} />
    </div>
  );
}

function ImageUpload({ image, onChange, note }) {
  return (
    <div className="image-upload">
      <img src={image} alt="" />
      <div>
        <label className="upload-button">
          <i className="fa-solid fa-upload" aria-hidden="true" />
          画像を変更
          <input type="file" accept="image/*" onChange={(event) => onChange(event.target.files?.[0])} />
        </label>
        <small>{note}</small>
      </div>
    </div>
  );
}

function MarketingSite() {
  const samples = [storeSamples.zakka, storeSamples.nail, storeSamples.gym];
  const steps = [
    ["1", "お店の情報を入れる", "店名、営業時間、写真、メニューを管理画面で入力します。"],
    ["2", "公開URLとQRを作る", "お客さんに渡すURLとQRコードをその場で作れます。"],
    ["3", "お店専用アプリ風に見せる", "お客さんはホーム画面に追加して、お店のアプリのように使えます。"],
  ];
  const coreFeatures = [
    ["fa-mobile-screen-button", "お客さん用ページ", "お店ごとのURLで、専用アプリのような画面を見せられます。"],
    ["fa-palette", "かんたん編集", "写真、色、メニュー、お知らせ、予約リンクを管理画面から変えられます。"],
    ["fa-qrcode", "QRコード作成", "店頭POPやチラシに載せるQRコードをすぐ作れます。"],
    ["fa-image", "画像リサイズ", "アップロードした画像を、アプリ用に自動で整えます。"],
  ];
  const businessPoints = [
    ["fa-coins", "初期費用をぐっと軽く", "専用アプリ開発を外注する前に、まずは2,000円で見せ方を整えられます。"],
    ["fa-store", "お店専用に見える", "お客さん側には、テンプレート感を抑えたお店専用ページとして見せられます。"],
    ["fa-chart-line", "すぐ販促に使える", "QRコードを店頭・SNS・チラシに置けば、その日から案内を始められます。"],
  ];

  return (
    <main className="marketing-site">
      <nav className="marketing-nav" aria-label="紹介サイトのナビゲーション">
        <a className="marketing-logo" href="/landing">
          <img src={appIcon} alt="" />
          <span>小さなお店の宣伝ツール</span>
        </a>
        <div>
          <a href="#value">価格の強み</a>
          <a href="#features">機能</a>
          <a href="#pricing">別料金</a>
          <a href="/">管理画面を見る</a>
        </div>
      </nav>

      <section
        className="marketing-hero"
        style={{
          backgroundImage: `linear-gradient(90deg, rgba(24, 35, 30, .92), rgba(24, 35, 30, .72) 48%, rgba(24, 35, 30, .2)), url(${zakkaHero})`,
        }}
      >
        <div className="marketing-hero-copy">
          <span className="marketing-kicker">2,000円で始めるお店アプリ風ページ</span>
          <h1>
            <span>小さなお店の</span>
            <span>宣伝ツール</span>
          </h1>
          <div className="price-punch">
            <span>アプリ開発を外注すると数百万円規模になりがち</span>
            <strong>まずは2,000円で、専用アプリ風の販促ページを作れます。</strong>
          </div>
          <p>
            店名、写真、メニューを入れるだけ。お客さんには「このお店専用のアプリみたい」と見えるページを作れます。
            高い開発費をかける前に、まずお店の見せ方を整えたい店主さん向けです。
          </p>
          <div className="marketing-actions">
            <a className="marketing-primary" href="/">
              管理画面を試す
              <i className="fa-solid fa-arrow-right" aria-hidden="true" />
            </a>
            <a className="marketing-secondary" href="#how-it-works">流れを見る</a>
          </div>
        </div>
        <div className="marketing-visual" aria-label="お店アプリのサンプル">
          <div className="marketing-card app-card">
            <img src={nailHero} alt="" />
            <div>
              <strong>2,000円で、お店専用アプリ風</strong>
              <span>雑貨屋・美容室・ネイルサロン・ジム</span>
            </div>
          </div>
          <div className="marketing-phone">
            <PhonePreview store={storeSamples.zakka} customerOnly />
          </div>
        </div>
      </section>

      <section className="value-strip" id="value">
        <article>
          <span>一般的な専用アプリ制作</span>
          <strong>数百万円規模</strong>
          <p>要件定義、デザイン、開発、審査、保守まで費用が大きくなりがちです。</p>
        </article>
        <article className="featured-value">
          <span>小さなお店の宣伝ツール</span>
          <strong>2,000円</strong>
          <p>まずはお店専用アプリ風ページ、QR、メニュー、告知をまとめて持てます。</p>
        </article>
        <article>
          <span>お客さんからの見え方</span>
          <strong>お店専用</strong>
          <p>表側はそのお店だけのページ。管理画面は店主さんだけが使います。</p>
        </article>
      </section>

      <section className="plain-message">
        <strong>高額なアプリ開発の前に、まず「お店専用に見える宣伝面」を持つ。</strong>
        <p>店主さんは管理画面で編集します。お客さんは、きれいに整ったお店ページだけを見ます。</p>
      </section>

      <section className="marketing-section" id="features">
        <div className="section-heading">
          <span>できること</span>
          <h2>お店の宣伝に必要なものを、ひとつにまとめます。</h2>
        </div>
        <div className="business-points">
          {businessPoints.map(([icon, title, text]) => (
            <article key={title}>
              <i className={`fa-solid ${icon}`} aria-hidden="true" />
              <strong>{title}</strong>
              <p>{text}</p>
            </article>
          ))}
        </div>
        <div className="feature-explainer">
          {coreFeatures.map(([icon, title, text]) => (
            <article key={title}>
              <i className={`fa-solid ${icon}`} aria-hidden="true" />
              <h3>{title}</h3>
              <p>{text}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="marketing-section sample-section">
        <div className="section-heading">
          <span>店舗サンプル</span>
          <h2>業種に合わせて、見た目も文章も変えられます。</h2>
        </div>
        <div className="sample-row">
          {samples.map((sample) => (
            <article key={sample.slug}>
              <img src={sample.hero} alt="" />
              <div>
                <strong>{sample.label}</strong>
                <p>{sample.subtitle}</p>
              </div>
            </article>
          ))}
        </div>
      </section>

      <section className="marketing-section steps-section" id="how-it-works">
        <div className="section-heading">
          <span>使い方</span>
          <h2>やることは3つだけです。</h2>
        </div>
        <div className="step-list">
          {steps.map(([number, title, text]) => (
            <article key={number}>
              <em>{number}</em>
              <h3>{title}</h3>
              <p>{text}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="marketing-section option-section" id="pricing">
        <div className="section-heading">
          <span>別料金メニュー</span>
          <h2>必要になった時だけ追加できます。</h2>
        </div>
        <div className="option-grid">
          {paidAddOns.map((addon) => (
            <article key={addon.title}>
              <i className={`fa-solid ${addon.icon}`} aria-hidden="true" />
              <strong>{addon.title}</strong>
              <p>{addon.description}</p>
              <span>{addon.status}</span>
            </article>
          ))}
        </div>
      </section>

      <section className="marketing-cta">
        <span>販売予定価格 2,000円</span>
        <h2>数百万円のアプリ開発に進む前に、まず2,000円で試す。</h2>
        <p>写真とメニューがあれば、すぐにお店専用アプリ風ページを試せます。</p>
        <a className="marketing-primary" href="/">
          管理画面を開く
          <i className="fa-solid fa-arrow-right" aria-hidden="true" />
        </a>
      </section>
    </main>
  );
}

function PhonePreview({ store, customerOnly = false }) {
  const visibleFeatures = featureOptions.filter((feature) => store.enabledFeatures[feature.key]);
  const bottomItems = [
    { key: "home", icon: "fa-house", label: "ホーム" },
    ...visibleFeatures.filter((feature) => ["products", "reservation", "coupon", "access"].includes(feature.key)),
  ].slice(0, 5);

  return (
    <div className={customerOnly ? "phone customer-phone" : "phone"} aria-label="お客さん用アプリプレビュー">
      <div className="phone-screen">
        <header className="app-header">
          <i className="fa-solid fa-bars" aria-hidden="true" />
          <strong>{store.name}</strong>
          <i className="fa-regular fa-bell" aria-hidden="true" />
        </header>
        <section className="app-hero" style={{ backgroundImage: `linear-gradient(180deg, rgba(0,0,0,.05), rgba(0,0,0,.58)), url(${store.hero})` }}>
          <img src={store.icon} alt="" />
          <h2>{store.subtitle}</h2>
          <span />
        </section>
        {store.enabledFeatures.coupon && store.showCampaign && (
          <section className="campaign">
            <img src={store.campaign} alt="キャンペーンバナー" />
            <div>
              <strong>{store.coupon}</strong>
              <small>{store.couponLimit}</small>
            </div>
          </section>
        )}
        <div className="quick-grid">
          {visibleFeatures.map((feature) => (
            <button key={feature.key}>
              <i className={`fa-solid ${feature.icon}`} aria-hidden="true" />
              {feature.key === "reservation" ? store.reservationLabel : feature.key === "products" ? store.productNavLabel : feature.shortLabel}
            </button>
          ))}
        </div>
        {store.enabledFeatures.news && (
          <section className="app-news">
            <div className="section-title">
              <h3>お知らせ</h3>
              <a>一覧へ</a>
            </div>
            {(store.news || []).map((news, index) => (
              <article key={news}>
                <time>2026/06/{10 + index}</time>
                <span>{index === 0 ? "NEW" : "INFO"}</span>
                <p>{news}</p>
                <i className="fa-solid fa-chevron-right" aria-hidden="true" />
              </article>
            ))}
          </section>
        )}
        {store.enabledFeatures.products && (
          <section className="product-strip">
            <div className="section-title">
              <h3>{store.productLabel}</h3>
              <a>もっと見る</a>
            </div>
            <div>
              <article>
                <strong>{store.productItems?.[0] || store.productLabel}</strong>
                <span>新入荷</span>
              </article>
              <article>
                <strong>{store.productItems?.[1] || "おすすめ"}</strong>
                <span>おすすめ</span>
              </article>
            </div>
          </section>
        )}
        <section className="shop-info">
          <p>{store.description}</p>
          <dl>
            <div>
              <dt>営業時間</dt>
              <dd>{store.hours}</dd>
            </div>
            <div>
              <dt>住所</dt>
              <dd>{store.address}</dd>
            </div>
          </dl>
        </section>
        <nav className="bottom-nav">
          {bottomItems.map((item, index) => (
            <button className={index === 0 ? "current" : ""} key={item.key}>
              <i className={`fa-solid ${item.icon}`} aria-hidden="true" />
              {item.key === "reservation" ? store.reservationLabel.replace("する", "") : item.shortLabel || item.label}
            </button>
          ))}
        </nav>
      </div>
    </div>
  );
}
