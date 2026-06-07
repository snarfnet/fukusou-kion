const EMPTY = 0;
const BLACK = 1;
const WHITE = 2;
const FILES = "ABCDEFGH";

const opponents = [
  {
    id: "ami",
    name: "Ami",
    level: 1,
    image: "assets/gyaru-othello/opponents/ami-neutral.jpg",
    expressions: {
      neutral: "assets/gyaru-othello/opponents/ami-neutral.jpg",
      think: "assets/gyaru-othello/opponents/ami-think.jpg",
      win: "assets/gyaru-othello/opponents/ami-win.jpg",
      lose: "assets/gyaru-othello/opponents/ami-lose.jpg"
    },
    title: "ノリ強めの初心者",
    style: "合法手から軽めに選ぶ。たまに角を見落とす。",
    depth: 0,
    noise: 42,
    lines: {
      start: "最初は軽くいくね。黒、どうぞ。",
      think: "んー、ここ置いたら返るやつ多い？",
      place: "はい、ここ。雰囲気で強そう。",
      win: "やった、勝った。今のは盛れた。",
      lose: "負けたけど、次は読んでくるから。",
      pain: "そこ打つの、ちょっと嫌かも。"
    }
  },
  {
    id: "rio",
    name: "Rio",
    level: 2,
    image: "assets/gyaru-othello/opponents/rio-neutral.jpg",
    expressions: {
      neutral: "assets/gyaru-othello/opponents/rio-neutral.jpg",
      think: "assets/gyaru-othello/opponents/rio-think.jpg",
      win: "assets/gyaru-othello/opponents/rio-win.jpg",
      lose: "assets/gyaru-othello/opponents/rio-lose.jpg"
    },
    title: "角だけは見てる",
    style: "角を優先する。危ない場所は少し避ける。",
    depth: 1,
    noise: 24,
    lines: {
      start: "Rioです。角は渡さないからね。",
      think: "ここで角の近く、触るか迷う。",
      place: "これで形、悪くないはず。",
      win: "読み勝ち。今のはちゃんと見えてた。",
      lose: "うわ、終盤で持っていかれた。",
      pain: "その手、けっこう刺さる。"
    }
  },
  {
    id: "mika",
    name: "Mika",
    level: 3,
    image: "assets/gyaru-othello/opponents/mika-neutral.jpg",
    expressions: {
      neutral: "assets/gyaru-othello/opponents/mika-neutral.jpg",
      think: "assets/gyaru-othello/opponents/mika-think.jpg",
      win: "assets/gyaru-othello/opponents/mika-win.jpg",
      lose: "assets/gyaru-othello/opponents/mika-lose.jpg"
    },
    title: "盤面バランス派",
    style: "石数より、相手の手を減らす手を選ぶ。",
    depth: 2,
    noise: 12,
    lines: {
      start: "Mikaね。序盤で石取りすぎると危ないよ。",
      think: "相手の手数、ここで削れるかな。",
      place: "はい、逃げ道ちょっと減らした。",
      win: "最後まで形作ったほうが勝ち。",
      lose: "そっちの寄せ、きれいだった。",
      pain: "やば、その位置は読んでなかった。"
    }
  },
  {
    id: "sena",
    name: "Sena",
    level: 4,
    image: "assets/gyaru-othello/opponents/sena-neutral.jpg",
    expressions: {
      neutral: "assets/gyaru-othello/opponents/sena-neutral.jpg",
      think: "assets/gyaru-othello/opponents/sena-think.jpg",
      win: "assets/gyaru-othello/opponents/sena-win.jpg",
      lose: "assets/gyaru-othello/opponents/sena-lose.jpg"
    },
    title: "終盤読みギャル",
    style: "2手先まで読み、角・辺・手数を重く見る。",
    depth: 3,
    noise: 5,
    lines: {
      start: "Sena。雑に置くとすぐ絞るよ。",
      think: "返した後の返しまで見る。",
      place: "ここ。次の手も込みで。",
      win: "形を崩させたから、こっちの勝ち。",
      lose: "強いね。そこまで読むなら本物。",
      pain: "今の一手でだいぶ細くなった。"
    }
  },
  {
    id: "noa",
    name: "Noa",
    level: 5,
    image: "assets/gyaru-othello/opponents/noa-neutral.jpg",
    expressions: {
      neutral: "assets/gyaru-othello/opponents/noa-neutral.jpg",
      think: "assets/gyaru-othello/opponents/noa-think.jpg",
      win: "assets/gyaru-othello/opponents/noa-win.jpg",
      lose: "assets/gyaru-othello/opponents/noa-lose.jpg"
    },
    title: "盤面制圧クイーン",
    style: "角・辺・可動力・危険マスをかなり厳しく評価する。",
    depth: 4,
    noise: 0,
    lines: {
      start: "Noaです。全力でいくから、遠慮なしね。",
      think: "終盤の枚数まで見て決める。",
      place: "ここで固定する。もう逃がさない。",
      win: "勝負あり。盤面、全部つながってた。",
      lose: "完敗。今のはあなたが上手い。",
      pain: "その一手、評価変わった。かなり良い。"
    }
  }
];

const opponentProfiles = {
  ami: {
    age: "22歳",
    food: "明太チーズもんじゃ",
    reason: "友達の家で朝まで打って、角を取った瞬間の気持ちよさに落ちた。",
    note: "勢いで打つけど、勝つときはちゃんと勝つ。負けてもすぐ笑うタイプ。"
  },
  rio: {
    age: "24歳",
    food: "海老アボカドの生春巻き",
    reason: "カフェの相席イベントで負けたのが悔しくて、次の日からアプリで毎晩練習した。",
    note: "見た目は余裕、内心はかなり負けず嫌い。角を取ると少しだけ口角が上がる。"
  },
  mika: {
    age: "21歳",
    food: "チーズタッカルビ",
    reason: "配信で視聴者と罰ゲーム対局をしたら盛り上がって、そのまま研究する側になった。",
    note: "リアクション大きめ。読めた時より、相手の読みを外した時に一番うれしそう。"
  },
  sena: {
    age: "25歳",
    food: "黒胡椒のきいたカルボナーラ",
    reason: "バーの常連に教わって、少ない石で相手を縛る感覚にハマった。",
    note: "話す量は少ないけど盤面はよく見てる。終盤になるほど目が鋭くなる。"
  },
  noa: {
    age: "27歳",
    food: "炙り寿司と赤だし",
    reason: "昔の大会動画を見て、最後の数手で全部ひっくり返る美しさに惚れた。",
    note: "勝負になると静か。強い手を打ったあとだけ、少しだけ笑う。"
  }
};

const weights = [
  [120, -24, 20, 8, 8, 20, -24, 120],
  [-24, -48, -6, -4, -4, -6, -48, -24],
  [20, -6, 12, 4, 4, 12, -6, 20],
  [8, -4, 4, 2, 2, 4, -4, 8],
  [8, -4, 4, 2, 2, 4, -4, 8],
  [20, -6, 12, 4, 4, 12, -6, 20],
  [-24, -48, -6, -4, -4, -6, -48, -24],
  [120, -24, 20, 8, 8, 20, -24, 120]
];

const boardEl = document.getElementById("board");
const blackScoreEl = document.getElementById("blackScore");
const whiteScoreEl = document.getElementById("whiteScore");
const turnStoneEl = document.getElementById("turnStone");
const turnTextEl = document.getElementById("turnText");
const opponentImageEl = document.getElementById("opponentImage");
const opponentStageEl = document.querySelector(".opponent-stage");
const dialogueEl = document.getElementById("dialogue");
const profileNameEl = document.getElementById("profileName");
const profileAgeEl = document.getElementById("profileAge");
const profileFoodEl = document.getElementById("profileFood");
const profileReasonEl = document.getElementById("profileReason");
const profileNoteEl = document.getElementById("profileNote");
const opponentSelectEl = document.getElementById("opponentSelect");
const opponentPickerEl = document.getElementById("opponentPicker");
const opponentPickerButtonEl = document.getElementById("opponentPickerButton");
const opponentPickerImageEl = document.getElementById("opponentPickerImage");
const opponentPickerTextEl = document.getElementById("opponentPickerText");
const opponentPickerMenuEl = document.getElementById("opponentPickerMenu");
const opponentListEl = document.getElementById("opponentList");
const styleTitleEl = document.getElementById("styleTitle");
const styleTextEl = document.getElementById("styleText");
const moveLogEl = document.getElementById("moveLog");
const resultOverlayEl = document.getElementById("resultOverlay");
const resultTitleEl = document.getElementById("resultTitle");
const resultScoreEl = document.getElementById("resultScore");
const resultQuoteEl = document.getElementById("resultQuote");
const handEl = document.getElementById("hand");

let board = [];
let turn = BLACK;
let activeOpponent = opponents[0];
let history = [];
let moveRecords = [];
let lastMoveKey = "";
let locked = false;

function createBoard() {
  board = Array.from({ length: 8 }, () => Array(8).fill(EMPTY));
  board[3][3] = WHITE;
  board[3][4] = BLACK;
  board[4][3] = BLACK;
  board[4][4] = WHITE;
  turn = BLACK;
  history = [];
  moveRecords = [];
  lastMoveKey = "";
  locked = false;
}

function rival(color) {
  return color === BLACK ? WHITE : BLACK;
}

function clone(source = board) {
  return source.map((row) => [...row]);
}

function flipsFor(source, row, col, color) {
  if (source[row][col] !== EMPTY) return [];
  const other = rival(color);
  const directions = [
    [-1, -1], [-1, 0], [-1, 1],
    [0, -1], [0, 1],
    [1, -1], [1, 0], [1, 1]
  ];
  const flips = [];

  for (const [dr, dc] of directions) {
    const line = [];
    let r = row + dr;
    let c = col + dc;
    while (r >= 0 && r < 8 && c >= 0 && c < 8 && source[r][c] === other) {
      line.push([r, c]);
      r += dr;
      c += dc;
    }
    if (line.length && r >= 0 && r < 8 && c >= 0 && c < 8 && source[r][c] === color) {
      flips.push(...line);
    }
  }
  return flips;
}

function legalMoves(source = board, color = turn) {
  const moves = [];
  for (let row = 0; row < 8; row += 1) {
    for (let col = 0; col < 8; col += 1) {
      const flips = flipsFor(source, row, col, color);
      if (flips.length) moves.push({ row, col, flips });
    }
  }
  return moves;
}

function applyMove(source, move, color) {
  const next = clone(source);
  next[move.row][move.col] = color;
  move.flips.forEach(([row, col]) => {
    next[row][col] = color;
  });
  return next;
}

function count(source = board) {
  return source.flat().reduce((acc, cell) => {
    if (cell === BLACK) acc.black += 1;
    if (cell === WHITE) acc.white += 1;
    return acc;
  }, { black: 0, white: 0 });
}

function notation(row, col) {
  return `${FILES[col]}${row + 1}`;
}

function evaluate(source, color) {
  const score = count(source);
  const my = color === BLACK ? score.black : score.white;
  const their = color === BLACK ? score.white : score.black;
  const mobility = legalMoves(source, color).length - legalMoves(source, rival(color)).length;
  let positional = 0;
  for (let row = 0; row < 8; row += 1) {
    for (let col = 0; col < 8; col += 1) {
      if (source[row][col] === color) positional += weights[row][col];
      if (source[row][col] === rival(color)) positional -= weights[row][col];
    }
  }
  return positional + mobility * 14 + (my - their) * 2;
}

function search(source, color, depth, alpha = -Infinity, beta = Infinity) {
  const moves = legalMoves(source, color);
  if (depth === 0 || (!moves.length && !legalMoves(source, rival(color)).length)) {
    return evaluate(source, WHITE);
  }
  if (!moves.length) return search(source, rival(color), depth - 1, alpha, beta);

  const maximizing = color === WHITE;
  let best = maximizing ? -Infinity : Infinity;
  for (const move of moves) {
    const next = applyMove(source, move, color);
    const value = search(next, rival(color), depth - 1, alpha, beta);
    if (maximizing) {
      best = Math.max(best, value);
      alpha = Math.max(alpha, value);
    } else {
      best = Math.min(best, value);
      beta = Math.min(beta, value);
    }
    if (beta <= alpha) break;
  }
  return best;
}

function pickAiMove() {
  const moves = legalMoves(board, WHITE);
  if (!moves.length) return null;
  const ranked = moves.map((move) => {
    const next = applyMove(board, move, WHITE);
    const depthValue = activeOpponent.depth > 0
      ? search(next, BLACK, activeOpponent.depth - 1)
      : evaluate(next, WHITE);
    const jitter = (Math.random() - .5) * activeOpponent.noise;
    return { ...move, value: depthValue + jitter + move.flips.length * (activeOpponent.level <= 2 ? 5 : 1) };
  }).sort((a, b) => b.value - a.value);
  return ranked[0];
}

function render() {
  const legal = turn === BLACK ? legalMoves(board, BLACK) : [];
  const legalKeys = new Set(legal.map((move) => `${move.row}-${move.col}`));
  boardEl.innerHTML = "";

  for (let row = 0; row < 8; row += 1) {
    for (let col = 0; col < 8; col += 1) {
      const cell = document.createElement("button");
      cell.className = "cell";
      cell.type = "button";
      cell.setAttribute("role", "gridcell");
      cell.setAttribute("aria-label", `${notation(row, col)} ${cellLabel(board[row][col])}`);
      cell.dataset.row = row;
      cell.dataset.col = col;
      setPerspectiveCell(cell, row, col);
      cell.addEventListener("click", (event) => {
        event.stopPropagation();
        handleCellSelection(cell);
      });
      const key = `${row}-${col}`;
      if (legalKeys.has(key)) cell.classList.add("legal");
      if (lastMoveKey === key) cell.classList.add("hint");
      if (board[row][col] !== EMPTY) {
        const disc = document.createElement("span");
        disc.className = `disc ${board[row][col] === BLACK ? "black" : "white"}`;
        cell.appendChild(disc);
      }
      boardEl.appendChild(cell);
    }
  }
  boardEl.appendChild(createPerspectiveGrid());

  const score = count();
  blackScoreEl.textContent = score.black;
  whiteScoreEl.textContent = score.white;
  turnStoneEl.className = `stone ${turn === BLACK ? "black" : "white"}`;
  turnTextEl.textContent = turn === BLACK ? "あなたの番" : `${activeOpponent.name}の番`;
  renderMoveLog();
}

function setPerspectiveCell(cell, row, col) {
  const topWidth = 1;
  const bottomWidth = 1;
  const rowTop = row / 8;
  const rowBottom = (row + 1) / 8;
  const topScale = topWidth + (bottomWidth - topWidth) * rowTop;
  const bottomScale = topWidth + (bottomWidth - topWidth) * rowBottom;
  const x1 = (1 - topScale) / 2 + (col * topScale) / 8;
  const x2 = (1 - topScale) / 2 + ((col + 1) * topScale) / 8;
  const x3 = (1 - bottomScale) / 2 + ((col + 1) * bottomScale) / 8;
  const x4 = (1 - bottomScale) / 2 + (col * bottomScale) / 8;
  const y1 = rowTop;
  const y2 = rowBottom;
  const centerX = (x1 + x2 + x3 + x4) / 4;
  const centerY = (y1 + y2) / 2;
  const left = Math.min(x1, x4);
  const right = Math.max(x2, x3);

  cell.style.setProperty("--left", `${left * 100}%`);
  cell.style.setProperty("--top", `${y1 * 100}%`);
  cell.style.setProperty("--width", `${(right - left) * 100}%`);
  cell.style.setProperty("--height", `${(y2 - y1) * 100}%`);
  cell.style.setProperty("--x1", `${x1 * 100}%`);
  cell.style.setProperty("--x2", `${x2 * 100}%`);
  cell.style.setProperty("--x3", `${x3 * 100}%`);
  cell.style.setProperty("--x4", `${x4 * 100}%`);
  cell.style.setProperty("--y1", `${y1 * 100}%`);
  cell.style.setProperty("--y2", `${y2 * 100}%`);
  cell.style.setProperty("--cx", `${((centerX - left) / (right - left)) * 100}%`);
  cell.style.setProperty("--cy", `${((centerY - y1) / (y2 - y1)) * 100}%`);
  cell.style.zIndex = String(row + 1);
}

function createPerspectiveGrid() {
  const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  svg.setAttribute("class", "board-grid");
  svg.setAttribute("viewBox", "0 0 1000 1000");
  svg.setAttribute("preserveAspectRatio", "none");
  const topWidth = 1;
  const bottomWidth = 1;

  for (let row = 0; row <= 8; row += 1) {
    const y = row / 8;
    const scale = topWidth + (bottomWidth - topWidth) * y;
    addGridLine(svg, (1 - scale) * 500, y * 1000, (1 + scale) * 500, y * 1000);
  }

  for (let col = 0; col <= 8; col += 1) {
    const topX = (1 - topWidth) * 500 + col * topWidth * 1000 / 8;
    const bottomX = col * 1000 / 8;
    addGridLine(svg, topX, 0, bottomX, 1000);
  }

  return svg;
}

function addGridLine(svg, x1, y1, x2, y2) {
  const line = document.createElementNS("http://www.w3.org/2000/svg", "line");
  line.setAttribute("x1", x1);
  line.setAttribute("y1", y1);
  line.setAttribute("x2", x2);
  line.setAttribute("y2", y2);
  svg.appendChild(line);
}

function cellLabel(cell) {
  if (cell === BLACK) return "黒";
  if (cell === WHITE) return "白";
  return "空き";
}

function setMood(mood, line) {
  opponentStageEl.classList.remove("thinking", "happy", "ouch");
  const expression = mood === "smile" ? "neutral" : mood;
  const image = activeOpponent.expressions?.[expression] || activeOpponent.expressions?.neutral || activeOpponent.image;
  if (opponentImageEl.getAttribute("src") !== image) {
    opponentImageEl.src = image;
  }
  if (mood === "think") opponentStageEl.classList.add("thinking");
  if (mood === "win" || mood === "smile") opponentStageEl.classList.add("happy");
  if (mood === "lose") opponentStageEl.classList.add("ouch");
  dialogueEl.textContent = line;
}

function playMove(move, color) {
  history.push({ board: clone(board), turn, lastMoveKey });
  moveRecords.push({ color, point: notation(move.row, move.col) });
  board = applyMove(board, move, color);
  lastMoveKey = `${move.row}-${move.col}`;
  turn = rival(color);
  addFlipAnimation(move.flips);
  render();
  if (isFinished()) return finishGame();
  handlePassOrNext();
}

function addFlipAnimation(flips) {
  requestAnimationFrame(() => {
    flips.forEach(([row, col]) => {
      const cell = boardEl.querySelector(`[data-row="${row}"][data-col="${col}"] .disc`);
      if (cell) cell.classList.add("flip");
    });
  });
}

function handlePassOrNext() {
  const moves = legalMoves(board, turn);
  if (!moves.length) {
    const otherMoves = legalMoves(board, rival(turn));
    if (!otherMoves.length) return finishGame();
    turn = rival(turn);
    setMood("smile", "置ける場所がないみたい。パスね。");
    render();
  }
  if (turn === WHITE) {
    locked = true;
    setMood("think", activeOpponent.lines.think);
    window.setTimeout(aiTurn, 720);
  } else {
    locked = false;
    const score = count();
    const mood = score.black > score.white ? "lose" : "smile";
    const line = score.black > score.white ? activeOpponent.lines.pain : "あなたの番。どこ置く？";
    setMood(mood, line);
  }
}

function aiTurn() {
  if (turn !== WHITE || isFinished()) return;
  const move = pickAiMove();
  if (!move) {
    handlePassOrNext();
    return;
  }
  animateHandTo(move);
  window.setTimeout(() => {
    setMood("win", activeOpponent.lines.place);
    playMove(move, WHITE);
  }, 980);
}

function animateHandTo(move) {
  const boardFrame = document.querySelector(".board-frame").getBoundingClientRect();
  const cell = boardEl.querySelector(`[data-row="${move.row}"][data-col="${move.col}"]`);
  const target = cell ? cell.getBoundingClientRect() : boardEl.getBoundingClientRect();
  handEl.style.left = `${target.left - boardFrame.left + target.width * .5}px`;
  handEl.style.top = `${target.top - boardFrame.top + target.height * .42}px`;
  handEl.classList.remove("play");
  void handEl.offsetWidth;
  handEl.classList.add("play");
}

function isFinished() {
  return !legalMoves(board, BLACK).length && !legalMoves(board, WHITE).length;
}

function finishGame() {
  locked = true;
  const score = count();
  let title = "引き分け";
  let mood = "smile";
  let line = "同点。これはもう一局でしょ。";
  let quote = "";
  if (score.black > score.white) {
    title = "あなたの勝ち";
    mood = "lose";
    line = activeOpponent.lines.lose;
    quote = `「${line}」`;
  }
  if (score.white > score.black) {
    title = `${activeOpponent.name}の勝ち`;
    mood = "win";
    line = activeOpponent.lines.win;
    quote = `「${line}」`;
  }
  resultTitleEl.textContent = title;
  resultScoreEl.textContent = `黒 ${score.black} - 白 ${score.white}`;
  if (resultQuoteEl) {
    resultQuoteEl.textContent = quote;
    resultQuoteEl.hidden = !quote;
  }
  resultOverlayEl.classList.add("show");
  setMood(mood, line);
}

function renderOpponentList() {
  if (opponentPickerMenuEl && !opponentPickerMenuEl.children.length) {
    opponents.forEach((opponent) => {
      const option = document.createElement("button");
      option.type = "button";
      option.className = "picker-option";
      option.dataset.id = opponent.id;
      option.setAttribute("role", "option");
      option.innerHTML = `
        <img src="${opponent.image}" alt="">
        <span><strong>${opponent.name}</strong><small>${opponent.title}</small></span>
        <span class="level-badge">Lv.${opponent.level}</span>
      `;
      opponentPickerMenuEl.appendChild(option);
    });
  }
  if (opponentPickerImageEl) opponentPickerImageEl.src = activeOpponent.image;
  if (opponentPickerTextEl) opponentPickerTextEl.textContent = `${activeOpponent.name} / Lv.${activeOpponent.level} ${activeOpponent.title}`;
  opponentPickerMenuEl?.querySelectorAll(".picker-option").forEach((option) => {
    option.setAttribute("aria-selected", String(option.dataset.id === activeOpponent.id));
  });
  if (opponentSelectEl && !opponentSelectEl.options.length) {
    opponents.forEach((opponent) => {
      const option = document.createElement("option");
      option.value = opponent.id;
      option.textContent = `${opponent.name} / Lv.${opponent.level} ${opponent.title}`;
      opponentSelectEl.appendChild(option);
    });
  }
  if (opponentSelectEl) opponentSelectEl.value = activeOpponent.id;
  if (opponentListEl) {
    opponentListEl.innerHTML = "";
    opponents.forEach((opponent) => {
      const button = document.createElement("button");
      button.type = "button";
      button.className = `opponent-card ${opponent.id === activeOpponent.id ? "active" : ""}`;
      button.dataset.id = opponent.id;
      button.innerHTML = `
        <img src="${opponent.image}" alt="">
        <span><strong>${opponent.name}</strong><small>${opponent.title}</small></span>
        <span class="level-badge">Lv.${opponent.level}</span>
      `;
      opponentListEl.appendChild(button);
    });
  }
  if (styleTitleEl) styleTitleEl.textContent = `${activeOpponent.name} / Lv.${activeOpponent.level}`;
  if (styleTextEl) styleTextEl.textContent = activeOpponent.style;
  renderProfile();
}

function renderProfile() {
  const profile = opponentProfiles[activeOpponent.id];
  if (!profile) return;
  profileNameEl.textContent = `${activeOpponent.name}のプロフィール`;
  profileAgeEl.textContent = profile.age;
  profileFoodEl.textContent = profile.food;
  profileReasonEl.textContent = profile.reason;
  profileNoteEl.textContent = profile.note;
}

function renderMoveLog() {
  if (!moveLogEl) return;
  moveLogEl.innerHTML = "";
  moveRecords.slice(-18).forEach((record, index) => {
    const li = document.createElement("li");
    const number = moveRecords.length - moveRecords.slice(-18).length + index + 1;
    const color = record.color === BLACK ? "黒" : "白";
    li.textContent = `${number}. ${color} ${record.point}`;
    moveLogEl.appendChild(li);
  });
}

function newGame() {
  createBoard();
  resultOverlayEl.classList.remove("show");
  opponentImageEl.alt = `${activeOpponent.name}のポートレート`;
  setMood("neutral", activeOpponent.lines.start);
  renderOpponentList();
  render();
}

function handleCellSelection(cell) {
  if (!cell || locked || turn !== BLACK) return;
  const row = Number(cell.dataset.row);
  const col = Number(cell.dataset.col);
  playPlayerMove(row, col);
}

function handleBoardPoint(clientX, clientY) {
  const rect = boardEl.getBoundingClientRect();
  const x = (clientX - rect.left) / rect.width;
  const y = (clientY - rect.top) / rect.height;
  if (x < 0 || x > 1 || y < 0 || y > 1) return;
  const row = Math.min(7, Math.max(0, Math.floor(y * 8)));
  const topWidth = 1;
  const rowCenter = (row + .5) / 8;
  const scale = topWidth + (1 - topWidth) * rowCenter;
  const left = (1 - scale) / 2;
  const col = Math.min(7, Math.max(0, Math.floor(((x - left) / scale) * 8)));
  playPlayerMove(row, col);
}

function playPlayerMove(row, col) {
  if (locked || turn !== BLACK) return;
  const move = legalMoves(board, BLACK).find((item) => item.row === row && item.col === col);
  if (!move) return;
  playMove(move, BLACK);
}

boardEl.addEventListener("click", (event) => {
  const cell = event.target.closest(".cell");
  if (cell) {
    handleCellSelection(cell);
    return;
  }
  handleBoardPoint(event.clientX, event.clientY);
});

if (opponentListEl) {
  opponentListEl.addEventListener("click", (event) => {
    const card = event.target.closest(".opponent-card");
    if (!card) return;
    activeOpponent = opponents.find((item) => item.id === card.dataset.id) || activeOpponent;
    newGame();
  });
}

if (opponentSelectEl) {
  opponentSelectEl.addEventListener("change", (event) => {
    activeOpponent = opponents.find((item) => item.id === event.target.value) || activeOpponent;
    newGame();
  });
}

if (opponentPickerButtonEl && opponentPickerEl) {
  opponentPickerButtonEl.addEventListener("click", () => {
    const isOpen = opponentPickerEl.classList.toggle("open");
    opponentPickerButtonEl.setAttribute("aria-expanded", String(isOpen));
  });
}

if (opponentPickerMenuEl && opponentPickerEl) {
  opponentPickerMenuEl.addEventListener("click", (event) => {
    const option = event.target.closest(".picker-option");
    if (!option) return;
    activeOpponent = opponents.find((item) => item.id === option.dataset.id) || activeOpponent;
    opponentPickerEl.classList.remove("open");
    opponentPickerButtonEl?.setAttribute("aria-expanded", "false");
    newGame();
  });
}

document.addEventListener("click", (event) => {
  if (!opponentPickerEl || opponentPickerEl.contains(event.target)) return;
  opponentPickerEl.classList.remove("open");
  opponentPickerButtonEl?.setAttribute("aria-expanded", "false");
});

document.getElementById("resetBtn").addEventListener("click", newGame);
document.getElementById("againBtn").addEventListener("click", newGame);

document.getElementById("undoBtn").addEventListener("click", () => {
  if (!history.length) return;
  const previous = history[0];
  if (history.length >= 2) {
    const target = history[history.length - 2];
    board = clone(target.board);
    turn = target.turn;
    lastMoveKey = target.lastMoveKey;
    history = history.slice(0, -2);
    moveRecords = moveRecords.slice(0, -2);
  } else {
    board = clone(previous.board);
    turn = previous.turn;
    lastMoveKey = previous.lastMoveKey;
    history = [];
    moveRecords = [];
  }
  locked = false;
  resultOverlayEl.classList.remove("show");
  setMood("neutral", "戻したよ。もう一回考えよ。");
  render();
});

document.getElementById("hintBtn").addEventListener("click", () => {
  if (turn !== BLACK || locked) return;
  const moves = legalMoves(board, BLACK);
  if (!moves.length) return;
  const best = moves
    .map((move) => ({ ...move, value: evaluate(applyMove(board, move, BLACK), BLACK) }))
    .sort((a, b) => b.value - a.value)[0];
  lastMoveKey = `${best.row}-${best.col}`;
  setMood("think", `おすすめは${notation(best.row, best.col)}。でも読まれてるかもね。`);
  render();
});

newGame();
