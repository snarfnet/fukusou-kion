const ASSETS = [
  { id: "hair", name: "盛り髪", category: "髪型", src: "assets/morimori-photo-maker/hair-glam.png", width: 62, x: 50, y: 23, z: 30 },
  { id: "hair-neon-twintails", name: "ネオンツイン", category: "髪型", src: "assets/morimori-photo-maker/hair-neon-twintails.png", width: 66, x: 50, y: 24, z: 30 },
  { id: "hair-silver-hime", name: "銀ハ姫カット", category: "髪型", src: "assets/morimori-photo-maker/hair-silver-hime.png", width: 64, x: 50, y: 25, z: 30 },
  { id: "hair-fire-lion", name: "炎ライオン", category: "髪型", src: "assets/morimori-photo-maker/hair-fire-lion.png", width: 68, x: 50, y: 25, z: 30 },
  { id: "hair-gothic-drill", name: "ゴシックドリル", category: "髪型", src: "assets/morimori-photo-maker/hair-gothic-drill.png", width: 66, x: 50, y: 24, z: 30 },
  { id: "hair-rainbow-puffs", name: "虹ふわパフ", category: "髪型", src: "assets/morimori-photo-maker/hair-rainbow-puffs.png", width: 68, x: 50, y: 24, z: 30 },
  { id: "brows", name: "強めまゆ", category: "まゆげ", src: "assets/morimori-photo-maker/brows-arch.png", width: 33, x: 50, y: 37, z: 45 },
  { id: "brows-villain-arch", name: "悪役アーチ", category: "まゆげ", src: "assets/morimori-photo-maker/brows-villain-arch.png", width: 33, x: 50, y: 37, z: 45 },
  { id: "brows-caramel-fluffy", name: "キャラメル太眉", category: "まゆげ", src: "assets/morimori-photo-maker/brows-caramel-fluffy.png", width: 34, x: 50, y: 37, z: 45 },
  { id: "brows-gold-lightning", name: "金イナズマ", category: "まゆげ", src: "assets/morimori-photo-maker/brows-gold-lightning.png", width: 35, x: 50, y: 37, z: 45 },
  { id: "brows-purple-moon", name: "紫ムーン", category: "まゆげ", src: "assets/morimori-photo-maker/brows-purple-moon.png", width: 35, x: 50, y: 37, z: 45 },
  { id: "brows-pink-heart", name: "ピンクハート", category: "まゆげ", src: "assets/morimori-photo-maker/brows-pink-heart.png", width: 35, x: 50, y: 37, z: 45 },
  { id: "eyes", name: "猫目ラメ", category: "アイシャドウ", src: "assets/morimori-photo-maker/eyes-cat-glitter.png", width: 42, x: 50, y: 43, z: 46 },
  { id: "shadow-blue-lightning", name: "青イナズマ", category: "アイシャドウ", src: "assets/morimori-photo-maker/shadow-blue-lightning.png", width: 43, x: 50, y: 43, z: 46 },
  { id: "shadow-sunset-butterfly", name: "夕焼け蝶", category: "アイシャドウ", src: "assets/morimori-photo-maker/shadow-sunset-butterfly.png", width: 44, x: 50, y: 43, z: 46 },
  { id: "shadow-gothic-crystal", name: "黒赤クリスタル", category: "アイシャドウ", src: "assets/morimori-photo-maker/shadow-gothic-crystal.png", width: 43, x: 50, y: 43, z: 46 },
  { id: "shadow-rainbow-prism", name: "虹プリズム", category: "アイシャドウ", src: "assets/morimori-photo-maker/shadow-rainbow-prism.png", width: 43, x: 50, y: 43, z: 46 },
  { id: "shadow-pink-pearl", name: "ピンク真珠", category: "アイシャドウ", src: "assets/morimori-photo-maker/shadow-pink-pearl.png", width: 43, x: 50, y: 43, z: 46 },
  { id: "blush-candy-sparkle", name: "キャンディ頬", category: "頬紅", src: "assets/morimori-photo-maker/blush-candy-sparkle.png", width: 42, x: 50, y: 55, z: 44 },
  { id: "blush-coral-stripe", name: "コーラル斜線", category: "頬紅", src: "assets/morimori-photo-maker/blush-coral-stripe.png", width: 42, x: 50, y: 55, z: 44 },
  { id: "blush-purple-star", name: "紫スター", category: "頬紅", src: "assets/morimori-photo-maker/blush-purple-star.png", width: 42, x: 50, y: 55, z: 44 },
  { id: "blush-heart-stamp", name: "ハート頬", category: "頬紅", src: "assets/morimori-photo-maker/blush-heart-stamp.png", width: 42, x: 50, y: 55, z: 44 },
  { id: "blush-gold-freckles", name: "金そばかす", category: "頬紅", src: "assets/morimori-photo-maker/blush-gold-freckles.png", width: 42, x: 50, y: 55, z: 44 },
  { id: "lips", name: "ぷる唇", category: "口紅", src: "assets/morimori-photo-maker/lips-gloss.png", width: 24, x: 50, y: 59, z: 47 },
  { id: "lipstick-neon-fuchsia", name: "ネオンピンク", category: "口紅", src: "assets/morimori-photo-maker/lipstick-neon-fuchsia.png", width: 24, x: 50, y: 59, z: 47 },
  { id: "lipstick-black-chrome", name: "黒クローム", category: "口紅", src: "assets/morimori-photo-maker/lipstick-black-chrome.png", width: 24, x: 50, y: 59, z: 47 },
  { id: "lipstick-gold-foil", name: "金箔リップ", category: "口紅", src: "assets/morimori-photo-maker/lipstick-gold-foil.png", width: 24, x: 50, y: 59, z: 47 },
  { id: "lipstick-red-heart", name: "赤ハート", category: "口紅", src: "assets/morimori-photo-maker/lipstick-red-heart.png", width: 24, x: 50, y: 59, z: 47 },
  { id: "lipstick-icy-blue", name: "氷ブルー", category: "口紅", src: "assets/morimori-photo-maker/lipstick-icy-blue.png", width: 24, x: 50, y: 59, z: 47 },
  { id: "glasses-heart-rhinestone", name: "ハートデカメガネ", category: "メガネ", src: "assets/morimori-photo-maker/glasses-heart-rhinestone.png", width: 43, x: 50, y: 43, z: 58 },
  { id: "glasses-star-holo", name: "星ホロメガネ", category: "メガネ", src: "assets/morimori-photo-maker/glasses-star-holo.png", width: 43, x: 50, y: 43, z: 58 },
  { id: "glasses-black-cateye", name: "黒キャットアイ", category: "メガネ", src: "assets/morimori-photo-maker/glasses-black-cateye.png", width: 42, x: 50, y: 43, z: 58 },
  { id: "earrings-heart-chandelier", name: "ハートシャンデリア", category: "イヤリング", src: "assets/morimori-photo-maker/earrings-heart-chandelier.png", width: 58, x: 50, y: 50, z: 42 },
  { id: "earrings-neon-hoop", name: "ネオンフープ", category: "イヤリング", src: "assets/morimori-photo-maker/earrings-neon-hoop.png", width: 54, x: 50, y: 50, z: 42 },
  { id: "earrings-gothic-cross", name: "ゴシック十字", category: "イヤリング", src: "assets/morimori-photo-maker/earrings-gothic-cross.png", width: 54, x: 50, y: 50, z: 42 },
  { id: "nose-pierce-mix-set", name: "鼻ピアスセット", category: "鼻ピアス", src: "assets/morimori-photo-maker/nose-pierce-mix-set.png", width: 16, x: 50, y: 51, z: 59 },
  { id: "nose-pierce-septum-pink", name: "ピンクセプタム", category: "鼻ピアス", src: "assets/morimori-photo-maker/nose-pierce-septum-pink.png", width: 14, x: 50, y: 52, z: 59 },
  { id: "nose-pierce-diamond-stud", name: "ダイヤ鼻ピ", category: "鼻ピアス", src: "assets/morimori-photo-maker/nose-pierce-diamond-stud.png", width: 9, x: 54, y: 51, z: 59 },
  { id: "halo", name: "キラ盛り", category: "パーツ", src: "assets/morimori-photo-maker/halo-sparkle.png", width: 90, x: 50, y: 49, z: 60 },
  { id: "burst", name: "派手フレーム", category: "背景", src: "assets/morimori-photo-maker/burst-frame.png", width: 100, x: 50, y: 50, z: 12 },
  { id: "burst-leopard-lightning", name: "豹柄ピカ盛り", category: "背景", src: "assets/morimori-photo-maker/burst-leopard-lightning.png", width: 100, x: 50, y: 50, z: 12 },
  { id: "kirakira", name: "キラキラMAX", category: "キラキラアニメ", src: "assets/morimori-photo-maker/kirakira-max-bg.gif", width: 100, x: 50, y: 50, z: 1, background: true },
  { id: "kirakira-pop", name: "ポップきらめき", category: "キラキラアニメ", src: "assets/morimori-photo-maker/kirakira-pop-bg.gif", width: 100, x: 50, y: 50, z: 1, background: true },
];

const CATEGORIES = ["髪型", "まゆげ", "アイシャドウ", "頬紅", "口紅", "メガネ", "イヤリング", "鼻ピアス", "背景", "キラキラアニメ", "パーツ"];

const PACKS = {
  free: {
    id: "free",
    name: "無料",
    productId: null,
    unlocked: true,
  },
  morimoriPack1: {
    id: "morimoriPack1",
    name: "盛り盛りパック1",
    productId: "com.tokyonasu.morimoriphotomaker.pack1",
    unlocked: false,
  },
  morimoriPack2: {
    id: "morimoriPack2",
    name: "盛り盛りパック2",
    productId: "com.tokyonasu.morimoriphotomaker.pack2",
    unlocked: false,
  },
};

const stage = document.querySelector("#stage");
const emptyState = document.querySelector("#emptyState");
const emptyPhotoButton = document.querySelector("#emptyPhotoButton");
const photoInput = document.querySelector("#photoInput");
const categoryTabs = document.querySelector("#categoryTabs");
const assetGrid = document.querySelector("#assetGrid");
const selectedName = document.querySelector("#selectedName");
const layerCount = document.querySelector("#layerCount");
const scaleRange = document.querySelector("#scaleRange");
const rotateRange = document.querySelector("#rotateRange");
const opacityRange = document.querySelector("#opacityRange");
const frontButton = document.querySelector("#frontButton");
const backButton = document.querySelector("#backButton");
const flipButton = document.querySelector("#flipButton");
const duplicateButton = document.querySelector("#duplicateButton");
const deleteButton = document.querySelector("#deleteButton");
const autoMoriButton = document.querySelector("#autoMoriButton");
const shareButton = document.querySelector("#shareButton");
const downloadButton = document.querySelector("#downloadButton");

let currentCategory = CATEGORIES[0];
let basePhoto = null;
let layers = [];
let selectedId = null;
let dragState = null;

function uid() {
  return `layer-${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

function renderTabs() {
  categoryTabs.innerHTML = "";
  CATEGORIES.forEach((category) => {
    const button = document.createElement("button");
    button.type = "button";
    button.textContent = category;
    button.className = category === currentCategory ? "active" : "";
    button.addEventListener("click", () => {
      currentCategory = category;
      renderTabs();
      renderAssets();
    });
    categoryTabs.appendChild(button);
  });
}

function renderAssets() {
  assetGrid.innerHTML = "";
  ASSETS.filter((asset) => asset.category === currentCategory).forEach((asset) => {
    const pack = getPack(asset);
    const locked = !isAssetUnlocked(asset);
    const card = document.createElement("button");
    card.type = "button";
    card.className = `asset-card${locked ? " locked" : ""}`;
    card.disabled = locked;
    card.title = locked ? `${pack.name}で使えます` : asset.name;
    card.innerHTML = `
      <span class="asset-thumb"><img src="${asset.src}" alt="">${locked ? '<b class="lock-badge">LOCK</b>' : ""}</span>
      <span>${asset.name}</span>
      ${pack.id === "free" ? "" : `<small class="pack-badge">${pack.name}</small>`}
    `;
    card.addEventListener("click", () => {
      if (locked) return;
      addLayer(asset);
    });
    assetGrid.appendChild(card);
  });
}

function addLayer(asset, overrides = {}) {
  if (!isAssetUnlocked(asset)) {
    return;
  }
  const layer = {
    id: uid(),
    assetId: asset.id,
    name: asset.name,
    src: asset.src,
    x: asset.x,
    y: asset.y,
    width: asset.width,
    rotation: 0,
    opacity: 1,
    flip: 1,
    z: asset.background ? asset.z : nextZ(asset.z),
    background: Boolean(asset.background),
    ...overrides,
  };
  layers.push(layer);
  selectedId = layer.id;
  renderLayers();
}

function getPack(asset) {
  return PACKS[asset.packId ?? "free"] ?? PACKS.free;
}

function isAssetUnlocked(asset) {
  return getPack(asset).unlocked;
}

function nextZ(base = 40) {
  const highest = layers.reduce((max, layer) => Math.max(max, layer.z), base);
  return Math.max(base, highest + 1);
}

function renderLayers() {
  emptyState.hidden = Boolean(basePhoto) || layers.length > 0;
  stage.querySelectorAll(".layer").forEach((node) => node.remove());
  const sorted = [...layers].sort((a, b) => a.z - b.z);
  sorted.forEach((layer) => {
    const el = document.createElement("div");
    el.className = `layer${layer.id === selectedId ? " selected" : ""}${layer.background ? " background" : ""}`;
    el.dataset.id = layer.id;
    const img = document.createElement("img");
    img.src = layer.src;
    img.alt = "";
    el.appendChild(img);
    applyLayerStyle(el, layer);
    el.addEventListener("pointerdown", startDrag);
    stage.appendChild(el);
  });
  updatePanel();
}

function applyLayerStyle(el, layer) {
  el.style.zIndex = layer.z;
  el.style.opacity = layer.opacity;
  if (layer.background) {
    el.style.transform = "none";
    return;
  }
  el.style.left = `${layer.x}%`;
  el.style.top = `${layer.y}%`;
  el.style.width = `${layer.width}%`;
  el.style.transform = `translate(-50%, -50%) rotate(${layer.rotation}deg) scaleX(${layer.flip})`;
}

function markSelectedLayer(id) {
  selectedId = id;
  stage.querySelectorAll(".layer").forEach((node) => {
    node.classList.toggle("selected", node.dataset.id === id);
  });
  updatePanel();
}

function updatePanel() {
  const selected = getSelected();
  selectedName.textContent = selected ? selected.name : "未選択";
  layerCount.textContent = `${layers.length} layers`;
  [scaleRange, rotateRange, opacityRange, frontButton, backButton, flipButton, duplicateButton, deleteButton].forEach((control) => {
    control.disabled = !selected || selected.background;
  });
  if (!selected) {
    return;
  }
  scaleRange.value = selected.width;
  rotateRange.value = selected.rotation;
  opacityRange.value = Math.round(selected.opacity * 100);
  if (selected.background) {
    opacityRange.disabled = false;
    deleteButton.disabled = false;
    duplicateButton.disabled = false;
  }
}

function getSelected() {
  return layers.find((layer) => layer.id === selectedId);
}

function startDrag(event) {
  const layer = layers.find((item) => item.id === event.currentTarget.dataset.id);
  if (!layer) return;
  markSelectedLayer(layer.id);
  if (layer.background) return;
  event.preventDefault();
  event.currentTarget.setPointerCapture(event.pointerId);
  event.currentTarget.classList.add("dragging");
  stage.classList.add("dragging");
  const rect = stage.getBoundingClientRect();
  dragState = {
    id: layer.id,
    element: event.currentTarget,
    startX: event.clientX,
    startY: event.clientY,
    originX: layer.x,
    originY: layer.y,
    rect,
  };
}

function onPointerMove(event) {
  if (!dragState) return;
  const layer = layers.find((item) => item.id === dragState.id);
  if (!layer) return;
  const dx = ((event.clientX - dragState.startX) / dragState.rect.width) * 100;
  const dy = ((event.clientY - dragState.startY) / dragState.rect.height) * 100;
  layer.x = Math.max(-20, Math.min(120, dragState.originX + dx));
  layer.y = Math.max(-20, Math.min(120, dragState.originY + dy));
  applyLayerStyle(dragState.element, layer);
}

function endDrag() {
  dragState?.element?.classList.remove("dragging");
  stage.classList.remove("dragging");
  dragState = null;
}

function changeSelected(mutator) {
  const selected = getSelected();
  if (!selected) return;
  mutator(selected);
  renderLayers();
}

function loadImage(src) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = reject;
    img.src = src;
  });
}

async function buildCompositeBlob() {
  const rect = stage.getBoundingClientRect();
  const canvas = document.createElement("canvas");
  canvas.width = 1080;
  canvas.height = 1440;
  const ctx = canvas.getContext("2d");
  ctx.fillStyle = "#ffd3ed";
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  const sorted = [...layers].sort((a, b) => a.z - b.z);
  for (const layer of sorted.filter((item) => item.z < 5)) {
    await drawLayer(ctx, layer, canvas);
  }
  if (basePhoto) {
    await drawCover(ctx, basePhoto, canvas.width, canvas.height);
  }
  for (const layer of sorted.filter((item) => item.z >= 5)) {
    await drawLayer(ctx, layer, canvas);
  }
  return new Promise((resolve) => canvas.toBlob(resolve, "image/png"));
}

async function downloadComposite() {
  const blob = await buildCompositeBlob();
  if (!blob) return;
  const link = document.createElement("a");
  link.download = "morimori-photo.png";
  link.href = URL.createObjectURL(blob);
  link.click();
  setTimeout(() => URL.revokeObjectURL(link.href), 1000);
}

async function shareComposite() {
  const blob = await buildCompositeBlob();
  if (!blob) return;
  const file = new File([blob], "morimori-photo.png", { type: "image/png" });
  if (navigator.canShare?.({ files: [file] })) {
    await navigator.share({
      files: [file],
      title: "盛り盛りフォトメーカー",
      text: "盛り盛りフォトメーカーで作った写真です",
    });
    return;
  }
  await downloadComposite();
}

async function drawCover(ctx, src, width, height) {
  const img = await loadImage(src);
  const scale = Math.max(width / img.naturalWidth, height / img.naturalHeight);
  const sw = img.naturalWidth * scale;
  const sh = img.naturalHeight * scale;
  ctx.drawImage(img, (width - sw) / 2, (height - sh) / 2, sw, sh);
}

async function drawLayer(ctx, layer, canvas) {
  const img = await loadImage(layer.src);
  ctx.save();
  ctx.globalAlpha = layer.opacity;
  if (layer.background) {
    ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
  } else {
    const x = (layer.x / 100) * canvas.width;
    const y = (layer.y / 100) * canvas.height;
    const w = (layer.width / 100) * canvas.width;
    const h = w;
    ctx.translate(x, y);
    ctx.rotate((layer.rotation * Math.PI) / 180);
    ctx.scale(layer.flip, 1);
    ctx.drawImage(img, -w / 2, -h / 2, w, h);
  }
  ctx.restore();
}

photoInput.addEventListener("change", (event) => {
  const file = event.target.files?.[0];
  if (!file) return;
  basePhoto = URL.createObjectURL(file);
  stage.querySelector(".base-photo")?.remove();
  const img = document.createElement("img");
  img.className = "base-photo";
  img.src = basePhoto;
  img.alt = "";
  stage.appendChild(img);
  emptyState.hidden = true;
  renderLayers();
});

emptyPhotoButton.addEventListener("click", () => {
  photoInput.click();
});

scaleRange.addEventListener("input", () => changeSelected((layer) => (layer.width = Number(scaleRange.value))));
rotateRange.addEventListener("input", () => changeSelected((layer) => (layer.rotation = Number(rotateRange.value))));
opacityRange.addEventListener("input", () => changeSelected((layer) => (layer.opacity = Number(opacityRange.value) / 100)));
frontButton.addEventListener("click", () => changeSelected((layer) => (layer.z = nextZ())));
backButton.addEventListener("click", () => changeSelected((layer) => (layer.z = 10)));
flipButton.addEventListener("click", () => changeSelected((layer) => (layer.flip *= -1)));
duplicateButton.addEventListener("click", () => {
  const selected = getSelected();
  if (!selected) return;
  const copy = { ...selected, id: uid(), x: selected.x + 4, y: selected.y + 4, z: nextZ(selected.z) };
  layers.push(copy);
  selectedId = copy.id;
  renderLayers();
});
deleteButton.addEventListener("click", () => {
  layers = layers.filter((layer) => layer.id !== selectedId);
  selectedId = layers.at(-1)?.id ?? null;
  renderLayers();
});
autoMoriButton.addEventListener("click", () => {
  ["kirakira", "hair", "brows", "eyes", "blush-candy-sparkle", "lips", "glasses-heart-rhinestone", "earrings-heart-chandelier", "halo"].forEach((id) => {
    const asset = ASSETS.find((item) => item.id === id);
    if (asset) addLayer(asset);
  });
});
downloadButton.addEventListener("click", downloadComposite);
shareButton.addEventListener("click", () => {
  shareComposite().catch((error) => {
    if (error?.name !== "AbortError") {
      console.error(error);
    }
  });
});
window.addEventListener("pointermove", onPointerMove);
window.addEventListener("pointerup", endDrag);

renderTabs();
renderAssets();
renderLayers();
