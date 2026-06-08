const fs = require("fs");
const path = require("path");

const file = path.join(__dirname, "..", "ios", "TroubleNavi", "TroubleNavi", "trouble_cases_curated.json");
const modelsFile = path.join(__dirname, "..", "ios", "TroubleNavi", "TroubleNavi", "Models.swift");
const payload = JSON.parse(fs.readFileSync(file, "utf8"));
const models = fs.readFileSync(modelsFile, "utf8");

const errors = [];
const warnings = [];
const required = ["id", "category", "urgency", "title", "summary", "steps", "avoid", "evidence", "contacts", "memo", "sourceKeys", "tags", "legalBoundary"];
const allowedUrgency = new Set(["高", "中", "低"]);
const titles = new Map();
const byCategory = new Map();

for (const item of payload.cases) {
  for (const key of required) {
    if (!(key in item)) errors.push(`${item.id || "(no id)"} missing ${key}`);
  }

  for (const key of ["steps", "avoid", "evidence", "contacts", "memo", "sourceKeys", "tags"]) {
    if (!Array.isArray(item[key]) || item[key].length === 0) errors.push(`${item.id} empty ${key}`);
  }

  if (!allowedUrgency.has(item.urgency)) errors.push(`${item.id} invalid urgency: ${item.urgency}`);
  if (titles.has(item.title)) errors.push(`${item.id} duplicate title: ${item.title}`);
  titles.set(item.title, item.id);
  byCategory.set(item.category, (byCategory.get(item.category) || 0) + 1);

  for (const key of item.sourceKeys) {
    if (!models.includes(`"${key}"`)) errors.push(`${item.id} source key missing in Models.swift: ${key}`);
  }
}

const moneyTitleTerms = [
  "お金", "送金", "請求", "カード", "フィッシング", "サポート詐欺", "料金", "報酬", "給料", "残業代", "費用",
  "購入", "契約", "通販", "サブスク", "税金", "家賃", "敷金", "退去", "支払", "月謝", "課金", "買い物",
  "キャンセル", "車", "中古車", "引っ越し", "修理", "家計", "財産", "年金", "相続", "通帳"
];
const moneyOutputTerms = ["送金履歴", "カード会社", "金融機関", "請求明細"];

for (const item of payload.cases) {
  const titleIsMoneyRelated = moneyTitleTerms.some((term) => item.title.includes(term));
  const outputText = [...item.evidence, ...item.contacts].join(" ");
  const hasMoneyOutput = moneyOutputTerms.some((term) => outputText.includes(term));
  if (!titleIsMoneyRelated && hasMoneyOutput) {
    errors.push(`${item.id} money-related evidence/contact looks unrelated: ${item.title}`);
  }
}

const snsBadMouth = payload.cases.find((item) => item.title === "悪口を書かれた");
if (!snsBadMouth) {
  errors.push("missing SNS case: 悪口を書かれた");
} else {
  const text = [...snsBadMouth.evidence, ...snsBadMouth.contacts].join(" ");
  for (const bad of ["送金履歴", "カード会社", "金融機関", "請求明細"]) {
    if (text.includes(bad)) errors.push(`悪口を書かれた includes unrelated term: ${bad}`);
  }
  for (const must of ["投稿URL", "スクリーンショット", "投稿日時", "投稿先プラットフォーム"]) {
    if (!text.includes(must)) errors.push(`悪口を書かれた missing expected term: ${must}`);
  }
}

for (const [category, count] of byCategory.entries()) {
  if (count < 8) warnings.push(`${category} has only ${count} cases`);
}

console.log(JSON.stringify({
  count: payload.cases.length,
  categories: byCategory.size,
  duplicateTitles: payload.cases.length - titles.size,
  errors: errors.length,
  warnings: warnings.length
}, null, 2));

if (warnings.length) {
  console.log("\nWarnings:");
  console.log(warnings.join("\n"));
}

if (errors.length) {
  console.log("\nErrors:");
  console.log(errors.join("\n"));
  process.exit(1);
}
