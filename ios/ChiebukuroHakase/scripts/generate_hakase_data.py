from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1] / "ChiebukuroHakase"
TARGET_COUNT = 50_000

CATEGORIES = [
    ("台所と保存", "Kitchen and Storage"),
    ("掃除と洗濯", "Cleaning and Laundry"),
    ("節約と買い物", "Saving and Shopping"),
    ("健康と養生", "Wellness Habits"),
    ("季節の暮らし", "Seasonal Living"),
    ("人づきあい", "Kind Relations"),
    ("ことわざ", "Proverbs"),
    ("防災と安全", "Safety at Home"),
    ("道具の手入れ", "Tool Care"),
    ("庭と植物", "Garden and Plants"),
    ("身だしなみ", "Care and Appearance"),
    ("家族と子育て", "Family and Children"),
    ("旅と外出", "Trips and Errands"),
    ("手紙と言葉", "Letters and Words"),
    ("昭和の暮らし", "Old Everyday Wisdom"),
    ("朝の支度", "Morning Routines"),
    ("夜の整え", "Evening Care"),
    ("食卓の工夫", "Table Wisdom"),
    ("雨の日", "Rainy Days"),
    ("小さな習慣", "Small Habits"),
]

OBJECTS = [
    ("茶碗", "rice bowl"), ("布巾", "dish cloth"), ("米びつ", "rice bin"),
    ("やかん", "kettle"), ("玄関", "entryway"), ("窓", "window"),
    ("財布", "wallet"), ("手帳", "notebook"), ("靴", "shoes"),
    ("鍋", "pot"), ("本棚", "bookshelf"), ("鏡", "mirror"),
    ("庭先", "front garden"), ("洗濯物", "laundry"), ("買い物袋", "shopping bag"),
    ("机", "desk"), ("台所", "kitchen"), ("押し入れ", "closet"),
    ("薬箱", "medicine box"), ("湯のみ", "teacup"),
]

SEASONS = [
    ("春", "spring"), ("梅雨", "rainy season"), ("夏", "summer"),
    ("秋", "autumn"), ("冬", "winter"), ("朝", "morning"),
    ("夕方", "evening"), ("月初め", "the start of the month"),
    ("休み明け", "the day after a holiday"), ("雨上がり", "after the rain"),
]

VERBS = [
    ("ひと拭きする", "wipe once"), ("先にしまう", "put away first"),
    ("日陰に置く", "keep in shade"), ("名前を付ける", "give it a name"),
    ("余白を残す", "leave a little room"), ("一晩休ませる", "let it rest overnight"),
    ("手前に出す", "place it near the front"), ("紙に書く", "write it down"),
    ("風を通す", "let air pass through"), ("小分けにする", "divide it into small portions"),
    ("声に出す", "say it aloud"), ("早めに畳む", "fold it early"),
    ("明るいうちに見る", "check it while it is bright"), ("同じ場所に戻す", "return it to the same place"),
    ("少しだけ残す", "leave a little"),
]

LESSONS = [
    ("あとで探す時間が減ります", "you will spend less time searching later"),
    ("翌日の気持ちが軽くなります", "tomorrow feels lighter"),
    ("無駄買いを避けやすくなります", "it becomes easier to avoid wasteful shopping"),
    ("小さな失敗に気づきやすくなります", "small mistakes become easier to notice"),
    ("家の空気が静かに整います", "the home begins to feel quietly ordered"),
    ("人への言葉も少しやわらぎます", "your words to others soften a little"),
    ("続けるほど手間が減ります", "the effort shrinks as you keep doing it"),
    ("急な用事にも慌てにくくなります", "sudden errands feel less rushed"),
    ("古い物を長く使えます", "old things last longer"),
    ("一日の終わりが穏やかになります", "the end of the day becomes calmer"),
]

TITLE_PATTERNS = [
    ("{season}の{object}は{verb}", "{season} {object}: {verb}"),
    ("{object}を整える小さな約束", "A small promise for the {object}"),
    ("{season}に思い出す{category}の知恵", "{category} wisdom for {season}"),
    ("おばぁちゃん博士の{object}メモ", "Grandma Scholar's note on the {object}"),
    ("迷ったら{object}から始める", "When unsure, begin with the {object}"),
]

CONTENT_PATTERNS = [
    "{object}は{season}ほど{verb}とよいです。{lesson}。",
    "忙しい日は、{object}を{verb}だけで十分です。小さく整えると、{lesson}。",
    "{category}は大げさに考えず、{object}を{verb}ところから始めます。すると{lesson}。",
    "昔から、手元の{object}を{verb}家は散らかりにくいと言います。{lesson}。",
    "気持ちが急ぐときほど、{object}を{verb}。一呼吸置けて、{lesson}。",
]

EN_CONTENT_PATTERNS = [
    "In {season}, {verb} the {object}. It helps because {lesson}.",
    "On a busy day, it is enough to {verb} the {object}. A small order helps because {lesson}.",
    "Do not make {category} too grand. Start with the {object}, {verb}, and {lesson}.",
    "Old households trusted one small habit: {verb} the {object}. That way, {lesson}.",
    "When your mind feels rushed, {verb} the {object}. It gives you a pause, and {lesson}.",
]

PROVERBS = [
    ("急がば回れ", "When in haste, take the roundabout way", "急ぐ日ほど手順を飛ばさないほうが、結局は早く片づきます。"),
    ("塵も積もれば山となる", "Many a little makes a mickle", "一日ひとつの片づけでも、月末には目に見える差になります。"),
    ("転ばぬ先の杖", "A cane before you stumble", "心配ごとは小さいうちに書き出すと、備えが具体的になります。"),
    ("継続は力なり", "Continuity is strength", "短い習慣を毎日続けるほうが、大きな決意より暮らしに残ります。"),
    ("笑う門には福来る", "Fortune visits a smiling gate", "先にあいさつを笑顔で置くと、その場の空気がやわらぎます。"),
]


def make_record(index: int, english: bool = False) -> dict[str, object]:
    category_ja, category_en = CATEGORIES[index % len(CATEGORIES)]
    object_ja, object_en = OBJECTS[(index // len(CATEGORIES)) % len(OBJECTS)]
    season_ja, season_en = SEASONS[(index // 7) % len(SEASONS)]
    verb_ja, verb_en = VERBS[(index // 11) % len(VERBS)]
    lesson_ja, lesson_en = LESSONS[(index // 13) % len(LESSONS)]

    if category_ja == "ことわざ" and index % 3 == 0:
        proverb = PROVERBS[(index // 3) % len(PROVERBS)]
        if english:
            title = proverb[1]
            content = f"A classic saying for ordinary life. Keep it small today: {verb_en} the {object_en}, and {lesson_en}."
            category = category_en
        else:
            title = proverb[0]
            content = f"{proverb[2]}今日は{object_ja}を{verb_ja}だけで十分です。"
            category = category_ja
        return {"id": index + 1, "title": title, "content": content, "category": category}

    title_pattern_ja, title_pattern_en = TITLE_PATTERNS[(index // 5) % len(TITLE_PATTERNS)]
    content_pattern_ja = CONTENT_PATTERNS[(index // 17) % len(CONTENT_PATTERNS)]
    content_pattern_en = EN_CONTENT_PATTERNS[(index // 17) % len(EN_CONTENT_PATTERNS)]

    if english:
        title = title_pattern_en.format(
            season=season_en,
            object=object_en,
            verb=verb_en,
            category=category_en,
        )
        content = content_pattern_en.format(
            season=season_en,
            object=object_en,
            verb=verb_en,
            category=category_en.lower(),
            lesson=lesson_en,
        )
        category = category_en
    else:
        title = title_pattern_ja.format(
            season=season_ja,
            object=object_ja,
            verb=verb_ja,
            category=category_ja,
        )
        content = content_pattern_ja.format(
            season=season_ja,
            object=object_ja,
            verb=verb_ja,
            category=category_ja,
            lesson=lesson_ja,
        )
        category = category_ja

    return {"id": index + 1, "title": title, "content": content, "category": category}


def main() -> None:
    ja = [make_record(index, english=False) for index in range(TARGET_COUNT)]
    en = [make_record(index, english=True) for index in range(TARGET_COUNT)]

    (ROOT / "wisdom_data.json").write_text(
        json.dumps(ja, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    (ROOT / "wisdom_data_en.json").write_text(
        json.dumps(en, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(f"wrote {len(ja)} Japanese records")
    print(f"wrote {len(en)} English records")
    print(ja[0])
    print(ja[1])


if __name__ == "__main__":
    main()
