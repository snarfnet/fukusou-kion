import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "data"
DOCS_DIR = ROOT / "docs"


THEMES = [
    {
        "key": "light",
        "ja": "光",
        "en": "Light",
        "angelic": ["IAIDA", "LUMIEL", "ORO", "ZACAR"],
        "actions": [
            ("朝の光を一分だけ見る。", "Look at the morning light for one minute."),
            ("部屋の暗い場所をひとつ整える。", "Clear one dim corner of your room."),
            ("白い紙に今日の願いを一文書く。", "Write today's wish on a white sheet of paper."),
        ],
    },
    {
        "key": "water",
        "ja": "水",
        "en": "Water",
        "angelic": ["LANSH", "MAZ", "VONPHO", "NIA"],
        "actions": [
            ("水を一杯飲んでから始める。", "Drink a glass of water before you begin."),
            ("手を洗いながら、気持ちを切り替える。", "Wash your hands and let your mood reset."),
            ("水の音を少しだけ聞く。", "Listen to the sound of water for a moment."),
        ],
    },
    {
        "key": "air",
        "ja": "風",
        "en": "Air",
        "angelic": ["EXARP", "ZIR", "NOCO", "PAL"],
        "actions": [
            ("窓を開けて、三回ゆっくり息をする。", "Open a window and take three slow breaths."),
            ("短い返事をひとつ送る。", "Send one short reply."),
            ("頭の中の言葉を三つだけ書き出す。", "Write down three words from your mind."),
        ],
    },
    {
        "key": "earth",
        "ja": "土",
        "en": "Earth",
        "angelic": ["NANTA", "GRAA", "MALPRG", "TORZU"],
        "actions": [
            ("足の裏を床につけて十秒止まる。", "Place your feet on the floor and pause for ten seconds."),
            ("机の上から一つだけ物を減らす。", "Remove one thing from your desk."),
            ("今日やることを一つだけ決める。", "Choose one thing to do today."),
        ],
    },
    {
        "key": "fire",
        "ja": "火",
        "en": "Fire",
        "angelic": ["BITOM", "OX", "PIR", "ZOMD"],
        "actions": [
            ("先延ばしにしたことを五分だけ進める。", "Work for five minutes on what you have delayed."),
            ("不要なメモをひとつ消す。", "Delete one note you no longer need."),
            ("心が熱くなる名前を一つ書く。", "Write one name that warms your heart."),
        ],
    },
    {
        "key": "moon",
        "ja": "月",
        "en": "Moon",
        "angelic": ["ARGED", "MICAOLZ", "LIL", "SOBRA"],
        "actions": [
            ("夜に今日の気分を一行だけ残す。", "Leave one line about your mood tonight."),
            ("眠る前に、明日聞きたい答えを一つ決める。", "Before sleep, choose one answer you want tomorrow."),
            ("部屋の明かりを少し落として深呼吸する。", "Dim the light a little and breathe deeply."),
        ],
    },
    {
        "key": "dream",
        "ja": "夢",
        "en": "Dream",
        "angelic": ["ZIMZ", "ZIEN", "LOHOLO", "ADNA"],
        "actions": [
            ("起きたら夢の断片を一つ書く。", "When you wake, write one fragment of a dream."),
            ("寝る前に、夢で見たい場所を決める。", "Before sleep, choose a place you want to see in a dream."),
            ("夢に出た色を一つ思い出す。", "Recall one color from a dream."),
        ],
    },
    {
        "key": "gate",
        "ja": "門",
        "en": "Gate",
        "angelic": ["ZIRDO", "LAP", "OBOLEH", "BALT"],
        "actions": [
            ("迷っていることを、入口と出口に分けて書く。", "Write what troubles you as an entrance and an exit."),
            ("閉じたいことを一つ、開きたいことを一つ書く。", "Write one thing to close and one thing to open."),
            ("今日は新しいタブを一つだけ開く。", "Open only one new tab today."),
        ],
    },
    {
        "key": "silence",
        "ja": "沈黙",
        "en": "Silence",
        "angelic": ["MAD", "HOATH", "CICLE", "PAID"],
        "actions": [
            ("通知を五分だけ止める。", "Pause notifications for five minutes."),
            ("返事を書く前に一呼吸置く。", "Take one breath before you reply."),
            ("何もしない時間を三分作る。", "Make three minutes for doing nothing."),
        ],
    },
    {
        "key": "heart",
        "ja": "心",
        "en": "Heart",
        "angelic": ["IAOD", "IPAM", "ZONRENSG", "TOH"],
        "actions": [
            ("自分に短い労いの言葉をかける。", "Give yourself one kind sentence."),
            ("大切な人の名前を一つ思い出す。", "Remember one name that matters to you."),
            ("胸のあたりに手を置いて、ゆっくり息をする。", "Place a hand on your chest and breathe slowly."),
        ],
    },
]


GUIDANCE = [
    ("焦らなくていい。今日の扉は、静かに開きます。", "You do not need to rush. Today's door opens quietly."),
    ("答えを急ぐより、問いをきれいに整えてください。", "Shape the question before you chase the answer."),
    ("小さな片づけが、心の通り道を作ります。", "One small act of clearing makes a path through the heart."),
    ("言葉を減らすほど、本音が見えやすくなります。", "When words grow fewer, the truth becomes easier to see."),
    ("今日は勝つ日ではなく、乱れを戻す日です。", "Today is not for winning. It is for restoring your balance."),
    ("胸の奥で光っているものを、見失わないでください。", "Do not lose sight of what glows deep in your chest."),
    ("迷いは敵ではありません。向きを変える合図です。", "Uncertainty is not an enemy. It is a sign to change direction."),
    ("誰かの声より、自分の呼吸を先に聞いてください。", "Listen to your breath before you listen to anyone else."),
    ("今あるものを数えると、足りないものの形が変わります。", "Count what is already here, and lack will change its shape."),
    ("深く考える前に、体を少し動かしてください。", "Move your body a little before thinking too deeply."),
    ("やさしさは、境界線を持っていても消えません。", "Kindness does not disappear when it has boundaries."),
    ("沈黙の中に、次の言葉の種があります。", "In silence, the next word is already a seed."),
    ("今日は大きな約束より、小さな実行を選んでください。", "Choose a small action over a large promise today."),
    ("見えない不安には、見える手順を与えてください。", "Give visible steps to invisible worry."),
    ("完璧に始める必要はありません。始めた形が道になります。", "You do not need a perfect start. The shape of starting becomes the path."),
    ("気になる名前を一つだけ、心の中で呼んでください。", "Call one name in your heart, just one."),
    ("失くしたと思った力は、休んでいただけです。", "The strength you thought was lost was only resting."),
    ("明るい答えほど、静かな場所で生まれます。", "The brightest answers are often born in quiet places."),
    ("今日は戻ることも前進です。", "Returning can also be progress today."),
    ("目の前の一つを丁寧に扱うと、流れが戻ります。", "Handle one thing before you with care, and the current will return."),
    ("心配を全部運ばなくていい。ひとつ置いていきましょう。", "You do not need to carry every worry. Leave one behind."),
    ("閉じた扉を責めず、開いている窓を探してください。", "Do not blame the closed door. Look for the open window."),
    ("今日の光は、派手ではなく確かです。", "Today's light is not loud, but it is steady."),
    ("誰にも見せない努力も、ちゃんと形になっています。", "The effort no one sees is still taking form."),
    ("気持ちが追いつかない時は、予定を小さくしてください。", "When your feelings lag behind, make the plan smaller."),
    ("ひとつ断ることで、ひとつ守れるものがあります。", "By refusing one thing, you may protect another."),
    ("夜に残った感情は、明日の地図になります。", "The feeling left at night becomes tomorrow's map."),
    ("強くなるとは、無理を増やすことではありません。", "Growing stronger does not mean adding more strain."),
    ("自分を責める声を、今日は少し遠くに置いてください。", "Place the voice that blames you a little farther away today."),
    ("見直す勇気は、やり直す力になります。", "The courage to review becomes the strength to begin again."),
    ("軽くできるものから軽くしてください。", "Lighten what can be lightened first."),
    ("今のあなたに必要なのは、証明より回復です。", "What you need now is recovery, not proof."),
    ("手放すものを決めると、受け取る場所が生まれます。", "When you choose what to release, a place to receive appears."),
    ("心の声は、急かすより待つ方がよく聞こえます。", "The heart is heard better by waiting than by rushing."),
    ("今日は、古い言葉を新しい意味に変える日です。", "Today, old words can take on a new meaning."),
    ("まだ形にならない願いにも、居場所をあげてください。", "Give a place to the wish that has not taken shape yet."),
    ("あなたの中の静かな部分が、もう答えを知っています。", "The quiet part of you already knows an answer."),
    ("遠くを見すぎたら、手元の光に戻ってください。", "If you look too far away, return to the light in your hands."),
    ("今日の合図は、小さく届きます。見逃さないでください。", "Today's sign will arrive softly. Do not miss it."),
    ("決められない時は、整えることから始めてください。", "When you cannot decide, begin by bringing order."),
    ("心が重い日は、言葉も軽くしていいです。", "On a heavy-hearted day, your words may be light."),
    ("大切なものほど、急いで結論にしないでください。", "Do not turn what matters into a conclusion too quickly."),
    ("あなたを疲れさせる役を、少し降りてもいいです。", "You may step down from the role that exhausts you."),
    ("小さな安心を先に作ると、勇気は後から来ます。", "Make a small safety first, and courage will follow."),
    ("今日は、探すより受け取る日です。", "Today is for receiving more than searching."),
    ("揺れている時ほど、足元を確かめてください。", "When you feel shaken, check the ground beneath you."),
    ("心の奥の違和感は、無視しないでください。", "Do not ignore the unease deep inside."),
    ("やさしい選択は、弱い選択ではありません。", "A gentle choice is not a weak choice."),
    ("今は遠回りに見える道が、あなたを守っています。", "The path that looks indirect may be protecting you now."),
    ("今日の一歩は、誰かに見せるためでなくていいです。", "Today's step does not need to be seen by anyone."),
    ("光は外から来るだけではありません。内側でも育ちます。", "Light does not only come from outside. It also grows within."),
    ("夢の中の象徴は、現実の気持ちを映します。", "Symbols in dreams reflect feelings in waking life."),
    ("名前をつけると、不安は少し小さくなります。", "When you name a worry, it becomes a little smaller."),
    ("今日のあなたには、余白が必要です。", "Today, you need some open space."),
    ("急に変えず、向きだけ少し変えてください。", "Do not change everything at once. Shift the direction a little."),
    ("誰かの期待より、今日の体力を信じてください。", "Trust today's energy more than someone else's expectation."),
    ("終わらせることにも、祝福があります。", "There can be blessing in ending something."),
    ("残すものを選ぶと、自分の輪郭が戻ります。", "Choosing what to keep brings your outline back."),
    ("心が動いた場所に、次の入口があります。", "Where your heart moved, the next entrance waits."),
    ("過去を責めず、今日の扱い方を変えてください。", "Do not blame the past. Change how you hold today."),
    ("あなたの願いは、静かな手入れを待っています。", "Your wish is waiting for quiet care."),
    ("見えない守りは、生活の小さな秩序に宿ります。", "Unseen protection lives in small order."),
    ("今日は、自分に戻るための短い道を選んでください。", "Choose a short path back to yourself today."),
    ("疑いが出たら、事実を三つだけ見てください。", "When doubt appears, look at only three facts."),
    ("胸が縮む場所から、少し距離を取ってください。", "Take a little distance from what tightens your chest."),
    ("まだ言えないことは、紙にだけ預けてもいいです。", "What you cannot say yet may be entrusted to paper."),
    ("正しさより、今のあなたに効くやさしさを選んでください。", "Choose the kindness that helps you now over being right."),
    ("流れが止まった時は、水ではなく石を見てください。", "When the flow stops, look not at the water but at the stone."),
    ("あなたの中の古い光が、今日また少し目を覚まします。", "An old light within you wakes a little today."),
    ("見守られている感覚を、急いで説明しなくていいです。", "You do not need to explain the feeling of being watched over."),
    ("今夜の夢に、ひとつ質問を渡してください。", "Give one question to tonight's dream."),
    ("小さな感謝は、心の扉を静かに開けます。", "Small gratitude quietly opens the heart's door."),
    ("今日は、必要なものだけ持って進んでください。", "Today, carry only what is needed."),
]


OPENERS = [
    ("天使は静かに告げます。", "The angel speaks softly."),
    ("今朝の光はこう伝えます。", "This morning's light says this."),
    ("あなたを守る声が届いています。", "A guarding voice reaches you."),
    ("見えない手紙には、こう書かれています。", "The unseen letter says this."),
    ("今日の門の前で、天使は言います。", "At today's gate, the angel says this."),
]


def angelic_phrase(day: int, theme: dict) -> str:
    words = theme["angelic"]
    other = THEMES[(day * 7) % len(THEMES)]["angelic"]
    parts = [
        words[day % len(words)],
        other[(day // 3) % len(other)],
        "OD" if day % 2 == 0 else "CA",
        words[(day + 1) % len(words)],
    ]
    if day % 9 == 0:
        parts.append("ZAMRAN")
    if day % 13 == 0:
        parts.insert(0, "ZACAR")
    return " ".join(parts)


def build_messages():
    messages = []
    for i in range(365):
        day = i + 1
        theme = THEMES[i % len(THEMES)]
        opener_ja, opener_en = OPENERS[i % len(OPENERS)]
        guidance_ja, guidance_en = GUIDANCE[i % len(GUIDANCE)]
        action_ja, action_en = theme["actions"][(i // len(THEMES)) % len(theme["actions"])]
        messages.append(
            {
                "day": day,
                "theme": theme["key"],
                "theme_ja": theme["ja"],
                "theme_en": theme["en"],
                "angelic": angelic_phrase(day, theme),
                "ja": f"{opener_ja}{guidance_ja}",
                "en": f"{opener_en} {guidance_en}",
                "action_ja": action_ja,
                "action_en": action_en,
                "tags": [theme["key"], "daily", "angel_message"],
            }
        )
    return messages


RULES = """# Angel Message Generation Rules

This file defines the app's daily message format.

## Format

Each message has three layers:

- angelic: Enochian-inspired sacred phrase. Treat this as atmosphere, not a strict scholarly translation.
- ja: Natural Japanese message.
- en: Natural English message.

Each entry also includes a tiny action. This keeps the app grounded.

## Tone

- Short, calm, and direct.
- Mystical, but not scary.
- No claims that the app predicts the future.
- No unsafe ritual instructions.
- The angel acts as a guide for reflection, not an authority.

## Message Shape

1. Angelic phrase
2. Japanese message
3. English message
4. One small action

## Safe Product Framing

Use phrases like:

- "今日のメッセージ"
- "天使語風の言葉"
- "内省のためのメッセージ"

Avoid phrases like:

- "必ず当たる"
- "本物の天使が命令する"
- "未来を断定する"

## Expansion Rule

To expand beyond 365 entries:

1. Choose one theme: light, water, air, earth, fire, moon, dream, gate, silence, heart.
2. Generate an angelic phrase from 3 to 5 uppercase tokens.
3. Write one Japanese sentence that points to a small inner shift.
4. Write one English sentence with the same meaning, not a word-for-word translation.
5. Add one action that can be done in under three minutes.
"""


def main():
    DATA_DIR.mkdir(exist_ok=True)
    DOCS_DIR.mkdir(exist_ok=True)

    payload = {
        "name": "Daily Angel Messages",
        "version": 1,
        "note_ja": "angelic はエノク語風の雰囲気フレーズです。厳密な翻訳ではありません。",
        "note_en": "The angelic field is Enochian-inspired atmosphere, not a strict translation.",
        "messages": build_messages(),
    }

    (DATA_DIR / "angel_messages_365.json").write_text(
        json.dumps(payload, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    (DOCS_DIR / "angel_message_generation_rules.md").write_text(RULES, encoding="utf-8")


if __name__ == "__main__":
    main()
