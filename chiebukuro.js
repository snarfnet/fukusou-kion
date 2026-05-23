(function () {
  const tips = Array.isArray(window.CHIEBUKURO_TIPS) && window.CHIEBUKURO_TIPS.length
    ? window.CHIEBUKURO_TIPS
    : [{ category: "暮らし", text: "今日の小さな手入れが、明日の自分を助ける。" }];

  const wisdomText = document.querySelector("#wisdomText");
  const typewriter = document.querySelector(".typewriter");
  const categoryLabel = document.querySelector("#categoryLabel");
  const flowLog = document.querySelector("#flowLog");
  const prevButton = document.querySelector("#prevButton");
  const nextButton = document.querySelector("#nextButton");
  const randomButton = document.querySelector("#randomButton");
  const pauseButton = document.querySelector("#pauseButton");

  let index = getTodayIndex();
  let typed = 0;
  let timerId = 0;
  let paused = false;
  let startedAt = 0;

  function getTodayIndex() {
    const todayKey = new Date().toISOString().slice(0, 10);
    let seed = 0;
    for (const char of todayKey) seed += char.charCodeAt(0);
    return seed % tips.length;
  }

  function normalizeTip(tip) {
    if (typeof tip === "string") {
      return { category: "知恵袋", text: tip };
    }

    const body = tip.text || tip.body || tip.content || "";
    const title = tip.title || "";
    const text = title && body && !body.startsWith(title)
      ? `${title}。${body}`
      : (body || title || "知恵が見つかりませんでした。");

    return {
      category: tip.category || "知恵袋",
      text
    };
  }

  function showTip(nextIndex, keepLog) {
    clearTimeout(timerId);
    index = (nextIndex + tips.length) % tips.length;
    typed = 0;
    startedAt = Date.now();

    const tip = normalizeTip(tips[index]);
    categoryLabel.textContent = tip.category;
    wisdomText.textContent = "";
    typewriter.classList.remove("breathing");
    if (!keepLog) addToFlow(tip);
    scheduleType();
  }

  function scheduleType() {
    if (paused) return;

    const tip = normalizeTip(tips[index]);
    if (typed <= tip.text.length) {
      wisdomText.textContent = tip.text.slice(0, typed);
      typed += 1;
      const lastChar = tip.text.charAt(typed - 2);
      const pause = "、。.".includes(lastChar) ? 220 : 54 + Math.random() * 42;
      timerId = setTimeout(scheduleType, pause);
      return;
    }

    typewriter.classList.add("breathing");
    const readingTime = Math.max(3400, Math.min(7200, tip.text.length * 120));
    timerId = setTimeout(() => showTip(index + 1), readingTime);
  }

  function addToFlow(tip) {
    const item = document.createElement("p");
    item.className = "flow-item";
    item.textContent = tip.text;
    flowLog.prepend(item);

    while (flowLog.children.length > 5) {
      flowLog.lastElementChild.remove();
    }
  }

  function togglePause() {
    paused = !paused;
    pauseButton.textContent = paused ? "▶" : "Ⅱ";
    pauseButton.setAttribute("aria-label", paused ? "再開" : "一時停止");

    if (!paused) {
      const stalled = Date.now() - startedAt > 30000;
      if (stalled) typed = Math.min(typed, normalizeTip(tips[index]).text.length);
      scheduleType();
    } else {
      clearTimeout(timerId);
    }
  }

  prevButton.addEventListener("click", () => showTip(index - 1));
  nextButton.addEventListener("click", () => showTip(index + 1));
  randomButton.addEventListener("click", () => {
    if (tips.length === 1) {
      showTip(0);
      return;
    }

    let nextIndex = index;
    while (nextIndex === index) {
      nextIndex = Math.floor(Math.random() * tips.length);
    }
    showTip(nextIndex);
  });
  pauseButton.addEventListener("click", togglePause);

  document.addEventListener("keydown", (event) => {
    if (event.key === "ArrowLeft") showTip(index - 1);
    if (event.key === "ArrowRight") showTip(index + 1);
    if (event.key === " ") {
      event.preventDefault();
      togglePause();
    }
  });

  showTip(index, true);
})();
