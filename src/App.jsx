import { useEffect, useMemo, useState } from "react";
import {
  Bell,
  BookOpen,
  CalendarCheck,
  CaretRight,
  ChartBar,
  Check,
  Drop,
  FirstAidKit,
  GearSix,
  House,
  PersonSimpleRun,
  Siren,
  Stethoscope,
  Sun,
  ThermometerHot,
  User,
  Warning,
} from "@phosphor-icons/react";
import { admobConfig } from "./admobConfig";
import doctorImage from "./assets/doctor-consultant.png";

const modes = [
  { id: "work", label: "屋外作業", icon: FirstAidKit, wbgt: 29, risk: "厳重警戒" },
  { id: "senior", label: "高齢者", icon: User, wbgt: 28, risk: "厳重警戒" },
  { id: "sport", label: "運動", icon: PersonSimpleRun, wbgt: 31, risk: "危険" },
];

const forecast = [
  { time: "9時", wbgt: 29, label: "厳重警戒", tone: "danger" },
  { time: "12時", wbgt: 31, label: "危険", tone: "critical" },
  { time: "15時", wbgt: 28, label: "厳重警戒", tone: "danger" },
  { time: "18時", wbgt: 25, label: "警戒", tone: "warn" },
  { time: "21時", wbgt: 21, label: "注意", tone: "safe" },
];

const symptomItems = ["めまい", "頭痛", "吐き気", "筋肉のけいれん", "体がだるい", "まっすぐ歩けない"];

const navItems = [
  { id: "home", label: "ホーム", icon: House },
  { id: "log", label: "記録", icon: ChartBar },
  { id: "forecast", label: "予報", icon: Sun },
  { id: "learn", label: "知識", icon: BookOpen },
  { id: "settings", label: "設定", icon: GearSix },
];

const adMobPlacement = {
  id: admobConfig.placementId,
  label: admobConfig.placementLabel,
  description: admobConfig.placementDescription,
};

function formatTimer(seconds) {
  const minutes = Math.floor(seconds / 60).toString().padStart(2, "0");
  const rest = (seconds % 60).toString().padStart(2, "0");
  return `${minutes}:${rest}`;
}

export function App() {
  const [mode, setMode] = useState("work");
  const [activeNav, setActiveNav] = useState("home");
  const [waterOn, setWaterOn] = useState(true);
  const [restOn, setRestOn] = useState(true);
  const [clothesOn, setClothesOn] = useState(true);
  const [waterTimer, setWaterTimer] = useState(323);
  const [restTimer, setRestTimer] = useState(1223);
  const [symptoms, setSymptoms] = useState([]);
  const [showEmergency, setShowEmergency] = useState(false);

  useEffect(() => {
    const timer = window.setInterval(() => {
      if (waterOn) setWaterTimer((value) => (value > 0 ? value - 1 : 15 * 60));
      if (restOn) setRestTimer((value) => (value > 0 ? value - 1 : 30 * 60));
    }, 1000);

    return () => window.clearInterval(timer);
  }, [waterOn, restOn]);

  const selectedMode = useMemo(() => modes.find((item) => item.id === mode), [mode]);
  const seriousSymptoms = symptoms.length >= 2;

  function toggleSymptom(item) {
    setSymptoms((current) =>
      current.includes(item) ? current.filter((symptom) => symptom !== item) : [...current, item],
    );
  }

  function logHydration() {
    setWaterTimer(15 * 60);
  }

  function logRest() {
    setRestTimer(30 * 60);
  }

  return (
    <main className="app-shell">
      <section className="phone">
        <div className="status-bar" aria-hidden="true">
          <span>9:41</span>
          <span>●●●  Wi-Fi  ▰</span>
        </div>

        <header className="hero">
          <img className="doctor-image" src={doctorImage} alt="監修医師の写真" />
          <div className="hero-copy">
            <div className="brand-mark">
              <FirstAidKit weight="fill" />
            </div>
            <div>
              <p className="eyebrow">熱中症予防サポート</p>
              <h1>医師とつくる、今日の安心</h1>
            </div>
          </div>

          <div className="doctor-note">
            <span>監修医師</span>
            <strong>佐藤 健一 医師</strong>
            <p>気温と湿度が高い状況です。こまめな水分・塩分補給と休憩を意識しましょう。</p>
          </div>
        </header>

        <div className="content">
          <section className="risk-panel" aria-labelledby="risk-title">
            <div className="section-heading">
              <div>
                <p className="mini-label">現在地: 千代田区</p>
                <h2 id="risk-title">今日のリスク</h2>
              </div>
              <time>6月17日 15:20</time>
            </div>

            <div className={`risk-summary ${selectedMode.wbgt >= 31 ? "critical" : ""}`}>
              <div className="wbgt-tile">
                <span>WBGT</span>
                <strong>{selectedMode.wbgt}</strong>
                <small>℃</small>
              </div>
              <div className="risk-message">
                <strong>{selectedMode.risk}</strong>
                <p>{selectedMode.wbgt >= 31 ? "屋外運動は中止を検討してください" : "熱中症の危険性が高いです"}</p>
                <div className="action-row">
                  <span><Drop weight="fill" /> 水分補給</span>
                  <span><CalendarCheck weight="fill" /> 定期休憩</span>
                  <span><Sun weight="fill" /> 涼しい環境</span>
                </div>
              </div>
            </div>
          </section>

          <section className="forecast-panel">
            <h2>時間ごとのリスク予報</h2>
            <div className="forecast-strip">
              {forecast.map((item) => (
                <button className={`forecast-item ${item.tone}`} key={item.time} type="button">
                  <span>{item.time}</span>
                  <Sun weight="fill" />
                  <strong>{item.wbgt}</strong>
                  <small>{item.label}</small>
                </button>
              ))}
            </div>
          </section>

          <section className="mode-panel">
            <h2>あなたの状況</h2>
            <div className="mode-grid" role="tablist" aria-label="活動モード">
              {modes.map((item) => {
                const Icon = item.icon;
                return (
                  <button
                    className={mode === item.id ? "mode-chip active" : "mode-chip"}
                    key={item.id}
                    type="button"
                    onClick={() => setMode(item.id)}
                    role="tab"
                    aria-selected={mode === item.id}
                  >
                    <Icon weight="fill" />
                    {item.label}
                  </button>
                );
              })}
            </div>
          </section>

          <section className="plan-panel">
            <div className="section-heading compact">
              <h2>今日の対策プラン</h2>
              <button className="text-button" type="button" onClick={() => setActiveNav("settings")}>
                設定
                <CaretRight />
              </button>
            </div>

            <PlanRow
              icon={Drop}
              tone="blue"
              title="15分ごとに水分補給"
              subtitle="次の水分補給まで"
              timer={formatTimer(waterTimer)}
              enabled={waterOn}
              onToggle={() => setWaterOn((value) => !value)}
              onAction={logHydration}
              actionLabel="飲んだ"
            />
            <PlanRow
              icon={CalendarCheck}
              tone="green"
              title="30分ごとに休憩"
              subtitle="次の休憩まで"
              timer={formatTimer(restTimer)}
              enabled={restOn}
              onToggle={() => setRestOn((value) => !value)}
              onAction={logRest}
              actionLabel="休憩した"
            />
            <PlanRow
              icon={ThermometerHot}
              tone="orange"
              title="塩分・電解質を補給"
              subtitle="目安: 1〜2時間ごと"
              actionLabel="記録"
              onAction={() => setShowEmergency(true)}
            />
            <PlanRow
              icon={Stethoscope}
              tone="cyan"
              title="涼しい服装・帽子の着用"
              subtitle="体温上昇を防ぎましょう"
              enabled={clothesOn}
              onToggle={() => setClothesOn((value) => !value)}
            />
          </section>

          <section className={seriousSymptoms ? "symptom-panel alert" : "symptom-panel"}>
            <div className="symptom-head">
              <div>
                <h2><Warning weight="fill" /> 症状チェック</h2>
                <p>当てはまる症状を選択</p>
              </div>
              <button type="button" onClick={() => setShowEmergency(true)}>
                緊急時の対応
                <CaretRight />
              </button>
            </div>

            <div className="symptom-grid">
              {symptomItems.map((item) => (
                <button
                  className={symptoms.includes(item) ? "symptom active" : "symptom"}
                  key={item}
                  type="button"
                  onClick={() => toggleSymptom(item)}
                >
                  <span>{symptoms.includes(item) && <Check weight="bold" />}</span>
                  {item}
                </button>
              ))}
            </div>

            {seriousSymptoms && (
              <p className="symptom-warning">複数の症状があります。涼しい場所へ移動し、必要なら119番へ連絡してください。</p>
            )}
          </section>

          <button className="sos-banner" type="button" onClick={() => setShowEmergency(true)}>
            <span>SOS</span>
            <strong>緊急時は迷わず119番</strong>
            <small>意識がない・呼吸がおかしい場合は、すぐに救急車を呼びましょう。</small>
          </button>

          <AdMobBanner />

          {activeNav !== "home" && (
            <section className="drawer-panel">
              <div>
                <h2>{navItems.find((item) => item.id === activeNav)?.label}</h2>
                <p>{activeNav === "settings" ? "通知間隔と広告表示位置を確認できます。" : "このプロトタイプでは主要操作の状態をここに集約しています。"}</p>
                {activeNav === "settings" && (
                  <dl className="settings-list">
                    <div>
                      <dt>広告表示</dt>
                      <dd>無料版のみ</dd>
                    </div>
                    <div>
                      <dt>表示位置</dt>
                      <dd>{adMobPlacement.label}</dd>
                    </div>
                    <div>
                      <dt>安全ルール</dt>
                      <dd>危険度・症状・SOSの近くには重ねません</dd>
                    </div>
                  </dl>
                )}
              </div>
              <button type="button" onClick={() => setActiveNav("home")}>ホームへ戻る</button>
            </section>
          )}
        </div>

        <nav className="bottom-nav" aria-label="主要ナビゲーション">
          {navItems.map((item) => {
            const Icon = item.icon;
            return (
              <button
                className={activeNav === item.id ? "nav-item active" : "nav-item"}
                key={item.id}
                type="button"
                onClick={() => setActiveNav(item.id)}
              >
                <Icon weight={activeNav === item.id ? "fill" : "regular"} />
                <span>{item.label}</span>
              </button>
            );
          })}
        </nav>

        {showEmergency && (
          <div className="modal-backdrop" role="presentation" onClick={() => setShowEmergency(false)}>
            <section className="emergency-modal" role="dialog" aria-modal="true" aria-labelledby="emergency-title" onClick={(event) => event.stopPropagation()}>
              <div className="modal-icon"><Siren weight="fill" /></div>
              <h2 id="emergency-title">緊急時の対応</h2>
              <p>意識がない、呼びかけに反応しない、体温が高い場合は119番へ連絡してください。</p>
              <ol>
                <li>涼しい場所へ移動する</li>
                <li>衣服をゆるめて体を冷やす</li>
                <li>飲める状態なら水分を少しずつ取る</li>
              </ol>
              <div className="modal-actions">
                <a href="tel:119">119番に電話</a>
                <button type="button" onClick={() => setShowEmergency(false)}>閉じる</button>
              </div>
            </section>
          </div>
        )}
      </section>
    </main>
  );
}

function AdMobBanner() {
  return (
    <aside
      className="admob-slot"
      aria-label="広告枠"
      data-ad-placement={adMobPlacement.id}
      data-ad-unit-id={admobConfig.bannerUnitId}
    >
      <div>
        <span>AdMob</span>
        <strong>スポンサー表示</strong>
      </div>
      <p>{adMobPlacement.description}</p>
    </aside>
  );
}

function PlanRow({ icon: Icon, tone, title, subtitle, timer, enabled, onToggle, onAction, actionLabel }) {
  return (
    <div className="plan-row">
      <div className={`plan-icon ${tone}`}><Icon weight="fill" /></div>
      <div className="plan-copy">
        <strong>{title}</strong>
        <span>{subtitle}</span>
      </div>
      {timer && <time>{timer}</time>}
      {actionLabel && (
        <button className="pill-action" type="button" onClick={onAction}>
          {actionLabel}
        </button>
      )}
      {typeof enabled === "boolean" && (
        <button
          className={enabled ? "toggle on" : "toggle"}
          type="button"
          onClick={onToggle}
          aria-pressed={enabled}
          aria-label={`${title}の通知`}
        >
          <span />
        </button>
      )}
    </div>
  );
}
