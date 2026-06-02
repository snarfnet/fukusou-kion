const REGIONS = {
  okinawa: { name: "沖縄本島", lat: 26.21, lon: 127.68 },
  miyako: { name: "宮古島", lat: 24.8, lon: 125.28 },
  kagoshima: { name: "鹿児島", lat: 31.6, lon: 130.56 },
  tokyo: { name: "東京", lat: 35.68, lon: 139.76 },
  osaka: { name: "大阪", lat: 34.69, lon: 135.5 },
  sendai: { name: "仙台", lat: 38.27, lon: 140.87 }
};

const SOURCE_CATALOG = [
  {
    id: "jma",
    name: "気象庁 防災情報",
    role: "日本向けの警報、注意報、台風発表。公式確認の軸。",
    url: "https://www.jma.go.jp/bosai/information/data/information.json"
  },
  {
    id: "digital",
    name: "Digital Typhoon Mf-JSON",
    role: "西太平洋の台風軌跡。研究利用しやすいJSON。",
    url: "https://agora.ex.nii.ac.jp/digital-typhoon/mf-json/wnp/2026.ja.json"
  },
  {
    id: "noaa",
    name: "NOAA NHC GIS",
    role: "大西洋・東太平洋の予報円、風域、警戒域。比較データに使う。",
    url: "https://mapservices.weather.noaa.gov/tropical/rest/services/tropical/NHC_tropical_weather/MapServer?f=pjson"
  },
  {
    id: "jtwc",
    name: "JTWC Warning",
    role: "米軍合同台風警報センター。西太平洋の英語速報の補助線。",
    url: "https://www.metoc.navy.mil/jtwc/jtwc.html"
  },
  {
    id: "openmeteo",
    name: "Open-Meteo / ECMWF",
    role: "地点別の風、雨量、気圧の予報。台風そのものではなく影響を読む。",
    url: "https://api.open-meteo.com/v1/forecast"
  },
  {
    id: "gdacs",
    name: "GDACS",
    role: "災害アラートと被害規模の把握。海外渡航者向け通知に使う。",
    url: "https://www.gdacs.org/"
  },
  {
    id: "wmo",
    name: "WMO Severe Weather",
    role: "各国気象機関の重大気象情報を束ねる確認口。",
    url: "https://severeweather.wmo.int/"
  },
  {
    id: "nasa",
    name: "NASA Worldview / GIBS",
    role: "衛星画像、海面水温、雲域の可視化。画像レイヤーの強化に使う。",
    url: "https://worldview.earthdata.nasa.gov/"
  },
  {
    id: "jaxa",
    name: "JAXA GSMaP",
    role: "衛星全球降水量。大雨リスクの裏取りに使う。",
    url: "https://sharaku.eorc.jaxa.jp/GSMaP/"
  },
  {
    id: "commercial",
    name: "商用天気API",
    role: "Weathernews、Tomorrow.io、OpenWeatherなど。通知品質とSLAが必要なら採用。",
    url: "https://openweathermap.org/api"
  }
];

const FALLBACK_STORM = {
  name: "台風サンプル 03W",
  source: "offline scenario",
  updatedAt: new Date().toISOString(),
  points: [
    { time: "2026-06-01T00:00:00+09:00", lat: 19.2, lon: 132.6, pressure: 992, wind: 40, forecast: false },
    { time: "2026-06-01T06:00:00+09:00", lat: 20.1, lon: 131.7, pressure: 985, wind: 45, forecast: false },
    { time: "2026-06-01T12:00:00+09:00", lat: 21.0, lon: 130.8, pressure: 975, wind: 55, forecast: false },
    { time: "2026-06-02T00:00:00+09:00", lat: 22.5, lon: 129.4, pressure: 965, wind: 65, forecast: true },
    { time: "2026-06-02T12:00:00+09:00", lat: 24.2, lon: 128.4, pressure: 960, wind: 70, forecast: true },
    { time: "2026-06-03T00:00:00+09:00", lat: 26.4, lon: 128.1, pressure: 965, wind: 65, forecast: true },
    { time: "2026-06-03T12:00:00+09:00", lat: 29.1, lon: 129.0, pressure: 975, wind: 55, forecast: true },
    { time: "2026-06-04T00:00:00+09:00", lat: 32.4, lon: 131.2, pressure: 985, wind: 45, forecast: true }
  ]
};

const canvas = document.querySelector("#trackCanvas");
const ctx = canvas.getContext("2d");
const state = {
  storm: FALLBACK_STORM,
  regionKey: "okinawa",
  view: "japan",
  showForecast: true,
  showRisk: true,
  hoverPoint: null,
  sourceStates: {}
};

document.querySelector("#regionSelect").addEventListener("change", (event) => {
  state.regionKey = event.target.value;
  render();
});

document.querySelector("#viewSelect").addEventListener("change", (event) => {
  state.view = event.target.value;
  render();
});

document.querySelector("#forecastToggle").addEventListener("change", (event) => {
  state.showForecast = event.target.checked;
  render();
});

document.querySelector("#riskToggle").addEventListener("change", (event) => {
  state.showRisk = event.target.checked;
  render();
});

document.querySelector("#refreshButton").addEventListener("click", loadLiveData);

canvas.addEventListener("mousemove", (event) => {
  const rect = canvas.getBoundingClientRect();
  const x = (event.clientX - rect.left) * (canvas.width / rect.width);
  const y = (event.clientY - rect.top) * (canvas.height / rect.height);
  state.hoverPoint = nearestCanvasPoint(x, y);
  renderCanvas();
  renderTooltip(event.clientX - rect.left, event.clientY - rect.top);
});

canvas.addEventListener("mouseleave", () => {
  state.hoverPoint = null;
  document.querySelector("#mapTooltip").hidden = true;
  renderCanvas();
});

async function loadLiveData() {
  markSource("digital", "取得中");
  markSource("jma", "確認中");
  markSource("noaa", "確認中");
  renderSources();

  const [digitalStorm, jmaState, noaaState] = await Promise.all([
    fetchDigitalTyphoon().catch(() => null),
    probeJson(SOURCE_CATALOG[0].url),
    probeJson(SOURCE_CATALOG[2].url)
  ]);

  markSource("jma", jmaState ? "接続OK" : "未接続");
  markSource("noaa", noaaState ? "接続OK" : "未接続");

  if (digitalStorm) {
    state.storm = digitalStorm;
    markSource("digital", "接続OK");
  } else {
    state.storm = FALLBACK_STORM;
    markSource("digital", "代替データ");
  }

  render();
}

async function fetchDigitalTyphoon() {
  const year = new Date().getFullYear();
  const url = `https://agora.ex.nii.ac.jp/digital-typhoon/mf-json/wnp/${year}.ja.json`;
  const response = await fetch(url, { cache: "no-store" });
  if (!response.ok) throw new Error("Digital Typhoon fetch failed");
  const data = await response.json();
  if (!Array.isArray(data) || data.length === 0) throw new Error("No typhoon features");

  const storms = data.map(normalizeMovingFeature).filter(Boolean);
  if (storms.length === 0) throw new Error("No valid features");
  storms.sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt));
  return { ...storms[0], source: "Digital Typhoon Mf-JSON" };
}

async function probeJson(url) {
  try {
    const response = await fetch(url, { cache: "no-store" });
    return response.ok;
  } catch {
    return false;
  }
}

function normalizeMovingFeature(feature) {
  const geometry = feature.temporalGeometry;
  if (!geometry || !Array.isArray(geometry.coordinates)) return null;

  const pressureProp = (feature.temporalProperties || []).find((item) => item.uom === "hPa");
  const windProp = (feature.temporalProperties || []).find((item) => item.uom === "kt");
  const points = geometry.coordinates.map((coordinate, index) => ({
    time: geometry.datetimes[index],
    lat: Number(coordinate[0]),
    lon: Number(coordinate[1]),
    pressure: Number(pressureProp?.values?.[index] || 0) || null,
    wind: Number(windProp?.values?.[index] || 0) || null,
    forecast: false
  })).filter((point) => Number.isFinite(point.lat) && Number.isFinite(point.lon));

  if (points.length === 0) return null;
  const last = points[points.length - 1];
  return {
    name: feature.properties?.name || "台風データ",
    source: "Digital Typhoon Mf-JSON",
    updatedAt: last.time,
    points
  };
}

function render() {
  renderCanvas();
  renderStatus();
  renderTable();
  renderSources();
}

function renderStatus() {
  const region = REGIONS[state.regionKey];
  const risk = calculateRisk(state.storm.points, region);
  const riskTitle = document.querySelector("#riskTitle");
  const riskFill = document.querySelector("#riskFill");
  const riskSummary = document.querySelector("#riskSummary");

  riskTitle.textContent = `${region.name} ${risk.label}`;
  riskFill.style.width = `${risk.score}%`;
  riskSummary.textContent = risk.summary;

  document.querySelector("#stormTitle").textContent = state.storm.name;
  document.querySelector("#sourceBadge").textContent = state.storm.source;
  document.querySelector("#updatedAt").textContent = `更新 ${formatTime(state.storm.updatedAt)}`;

  const latest = state.storm.points[state.storm.points.length - 1];
  const metrics = [
    ["最接近", risk.closestTime ? formatTime(risk.closestTime) : "不明"],
    ["最短距離", `${Math.round(risk.closestKm)} km`],
    ["中心気圧", latest.pressure ? `${latest.pressure} hPa` : "不明"],
    ["最大風速", latest.wind ? `${latest.wind} kt` : "不明"]
  ];
  document.querySelector("#metricGrid").innerHTML = metrics.map(([label, value]) => (
    `<div class="metric"><span>${label}</span><strong>${value}</strong></div>`
  )).join("");

  const advice = buildAdvice(risk);
  document.querySelector("#adviceList").innerHTML = advice.map((item) => `<li>${item}</li>`).join("");
}

function renderTable() {
  const region = REGIONS[state.regionKey];
  const rows = state.storm.points.slice(-12).map((point) => {
    const distance = haversineKm(point, region);
    return `<tr>
      <td data-label="時刻">${formatTime(point.time)}</td>
      <td data-label="位置">${point.lat.toFixed(1)}N / ${point.lon.toFixed(1)}E</td>
      <td data-label="中心気圧">${point.pressure ? `${point.pressure} hPa` : "不明"}</td>
      <td data-label="最大風速">${point.wind ? `${point.wind} kt` : "不明"}</td>
      <td data-label="監視地点まで">${Math.round(distance)} km</td>
    </tr>`;
  });
  document.querySelector("#trackTable").innerHTML = rows.join("");
}

function renderSources() {
  document.querySelector("#sourceList").innerHTML = SOURCE_CATALOG.map((source) => {
    const stateText = state.sourceStates[source.id] || "待機";
    return `<article class="source-card">
      <h3>${source.name}</h3>
      <p>${source.role}</p>
      <a href="${source.url}" target="_blank" rel="noreferrer">URLを開く</a>
      <span class="state">${stateText}</span>
    </article>`;
  }).join("");
}

function renderCanvas() {
  const { width, height } = canvas;
  const bounds = state.view === "wide"
    ? { minLat: 0, maxLat: 48, minLon: 110, maxLon: 160 }
    : { minLat: 18, maxLat: 46, minLon: 120, maxLon: 148 };

  ctx.clearRect(0, 0, width, height);
  drawOcean(width, height);
  drawGrid(bounds);
  drawJapanSketch(bounds);
  drawTrack(bounds);
  drawRegion(bounds);
}

function drawOcean(width, height) {
  const gradient = ctx.createLinearGradient(0, 0, width, height);
  gradient.addColorStop(0, "#155f6b");
  gradient.addColorStop(1, "#061f27");
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, width, height);

  ctx.globalAlpha = 0.2;
  ctx.strokeStyle = "#bff7ef";
  for (let i = -height; i < width; i += 42) {
    ctx.beginPath();
    ctx.moveTo(i, height);
    ctx.lineTo(i + height, 0);
    ctx.stroke();
  }
  ctx.globalAlpha = 1;
}

function drawGrid(bounds) {
  ctx.strokeStyle = "rgba(214, 255, 248, 0.18)";
  ctx.fillStyle = "rgba(238, 254, 251, 0.68)";
  ctx.lineWidth = 1;
  ctx.font = "12px sans-serif";
  for (let lon = Math.ceil(bounds.minLon / 5) * 5; lon <= bounds.maxLon; lon += 5) {
    const x = project({ lat: bounds.minLat, lon }, bounds).x;
    ctx.beginPath();
    ctx.moveTo(x, 0);
    ctx.lineTo(x, canvas.height);
    ctx.stroke();
    ctx.fillText(`${lon}E`, x + 4, 18);
  }
  for (let lat = Math.ceil(bounds.minLat / 5) * 5; lat <= bounds.maxLat; lat += 5) {
    const y = project({ lat, lon: bounds.minLon }, bounds).y;
    ctx.beginPath();
    ctx.moveTo(0, y);
    ctx.lineTo(canvas.width, y);
    ctx.stroke();
    ctx.fillText(`${lat}N`, 8, y - 5);
  }
}

function drawJapanSketch(bounds) {
  const islands = [
    [{ lat: 31, lon: 130 }, { lat: 34, lon: 132 }, { lat: 35.4, lon: 136 }, { lat: 37, lon: 139 }, { lat: 40, lon: 141.5 }, { lat: 43.2, lon: 144 }],
    [{ lat: 26.1, lon: 127.6 }, { lat: 26.4, lon: 128.2 }],
    [{ lat: 24.8, lon: 125.3 }, { lat: 24.9, lon: 125.6 }]
  ];
  ctx.strokeStyle = "rgba(244, 240, 231, 0.72)";
  ctx.lineWidth = 5;
  ctx.lineCap = "round";
  islands.forEach((island) => {
    ctx.beginPath();
    island.forEach((point, index) => {
      const p = project(point, bounds);
      if (index === 0) ctx.moveTo(p.x, p.y);
      else ctx.lineTo(p.x, p.y);
    });
    ctx.stroke();
  });
}

function drawTrack(bounds) {
  const points = state.storm.points.filter((point) => state.showForecast || !point.forecast);
  if (points.length === 0) return;

  ctx.lineWidth = 4;
  ctx.strokeStyle = "#f7e7a4";
  ctx.beginPath();
  points.forEach((point, index) => {
    const p = project(point, bounds);
    if (index === 0) ctx.moveTo(p.x, p.y);
    else ctx.lineTo(p.x, p.y);
  });
  ctx.stroke();

  points.forEach((point, index) => {
    const p = project(point, bounds);
    const radius = point.forecast ? 10 + index * 2 : 8;
    if (point.forecast && state.showForecast) {
      ctx.fillStyle = "rgba(229, 88, 61, 0.16)";
      ctx.strokeStyle = "rgba(229, 88, 61, 0.38)";
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.arc(p.x, p.y, radius * 2.8, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
    }
    ctx.fillStyle = point.forecast ? "#e5583d" : "#74d1c6";
    ctx.strokeStyle = "#fffaf0";
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(p.x, p.y, radius, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();
  });

  if (state.hoverPoint) {
    const p = project(state.hoverPoint, bounds);
    ctx.strokeStyle = "#fffaf0";
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.arc(p.x, p.y, 18, 0, Math.PI * 2);
    ctx.stroke();
  }
}

function drawRegion(bounds) {
  if (!state.showRisk) return;
  const region = REGIONS[state.regionKey];
  const p = project(region, bounds);
  const risk = calculateRisk(state.storm.points, region);
  ctx.fillStyle = "rgba(255, 250, 240, 0.92)";
  ctx.strokeStyle = risk.score > 70 ? "#e5583d" : "#74d1c6";
  ctx.lineWidth = 3;
  ctx.beginPath();
  ctx.arc(p.x, p.y, 9, 0, Math.PI * 2);
  ctx.fill();
  ctx.stroke();
  ctx.fillStyle = "#fffaf0";
  ctx.font = "bold 14px sans-serif";
  ctx.fillText(region.name, p.x + 14, p.y - 12);
}

function project(point, bounds) {
  const padding = 44;
  const x = padding + ((point.lon - bounds.minLon) / (bounds.maxLon - bounds.minLon)) * (canvas.width - padding * 2);
  const y = padding + ((bounds.maxLat - point.lat) / (bounds.maxLat - bounds.minLat)) * (canvas.height - padding * 2);
  return { x, y };
}

function nearestCanvasPoint(x, y) {
  const bounds = state.view === "wide"
    ? { minLat: 0, maxLat: 48, minLon: 110, maxLon: 160 }
    : { minLat: 18, maxLat: 46, minLon: 120, maxLon: 148 };
  let nearest = null;
  let nearestDistance = Infinity;
  state.storm.points.forEach((point) => {
    const p = project(point, bounds);
    const distance = Math.hypot(p.x - x, p.y - y);
    if (distance < nearestDistance) {
      nearest = point;
      nearestDistance = distance;
    }
  });
  return nearestDistance < 36 ? nearest : null;
}

function renderTooltip(x, y) {
  const tooltip = document.querySelector("#mapTooltip");
  if (!state.hoverPoint) {
    tooltip.hidden = true;
    return;
  }
  tooltip.hidden = false;
  tooltip.style.left = `${Math.min(x + 14, canvas.clientWidth - 240)}px`;
  tooltip.style.top = `${Math.max(y - 14, 12)}px`;
  tooltip.innerHTML = `<strong>${formatTime(state.hoverPoint.time)}</strong><br>
    ${state.hoverPoint.lat.toFixed(1)}N / ${state.hoverPoint.lon.toFixed(1)}E<br>
    ${state.hoverPoint.pressure || "不明"} hPa / ${state.hoverPoint.wind || "不明"} kt`;
}

function calculateRisk(points, region) {
  let closest = { distance: Infinity, point: null };
  points.forEach((point) => {
    const distance = haversineKm(point, region);
    if (distance < closest.distance) closest = { distance, point };
  });

  const strongestWind = Math.max(...points.map((point) => point.wind || 0));
  const distanceScore = Math.max(0, 100 - closest.distance / 6);
  const windScore = Math.min(100, strongestWind * 1.2);
  const score = Math.round(distanceScore * 0.62 + windScore * 0.38);
  const label = score > 72 ? "高警戒" : score > 44 ? "注意" : "監視";
  const summary = score > 72
    ? "進路が近く、風雨の影響を強く受ける想定です。公式発表と避難情報を短い間隔で確認してください。"
    : score > 44
      ? "接近の可能性があります。風、雨、交通の乱れを早めに見てください。"
      : "現時点の接近度は低めです。進路が変わる前提で、更新を確認してください。";

  return {
    score,
    label,
    summary,
    closestKm: closest.distance,
    closestTime: closest.point?.time,
    strongestWind
  };
}

function buildAdvice(risk) {
  if (risk.score > 72) {
    return ["気象庁の警報、自治体の避難情報を優先して確認", "停電、断水、交通停止を想定して今日中に備蓄を点検", "海岸、河川、用水路には近づかない"];
  }
  if (risk.score > 44) {
    return ["48時間以内の予定を見直す", "雨雲レーダーと風予報を併用", "ベランダや屋外の飛びやすい物を片付ける"];
  }
  return ["1日2回は進路更新を確認", "旅行や離島移動は欠航情報も見る", "発達予想が強まったら通知対象に入れる"];
}

function haversineKm(a, b) {
  const earth = 6371;
  const dLat = toRad(b.lat - a.lat);
  const dLon = toRad(b.lon - a.lon);
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2;
  return 2 * earth * Math.asin(Math.sqrt(h));
}

function toRad(value) {
  return value * Math.PI / 180;
}

function formatTime(value) {
  if (!value) return "不明";
  const date = new Date(value);
  return new Intl.DateTimeFormat("ja-JP", {
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit"
  }).format(date);
}

function markSource(id, label) {
  state.sourceStates[id] = label;
}

render();
loadLiveData();
