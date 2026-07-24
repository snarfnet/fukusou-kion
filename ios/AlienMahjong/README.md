# Moonshot Mahjong

An English-language iOS game about deciding humanity's fate at a mahjong table.

Four alien champions stand between Earth and extinction:

- Xen-7, the Grey envoy
- Varak, the Reptilian warlord
- Six-Eyes, the Mantis strategist
- The Prism, the Crystal sovereign

## Current playable rules

- Heads-up riichi mahjong using a complete 136-tile wall.
- Draw one tile and discard one tile in alternating turns.
- A legal standard hand is four melds and one pair.
- Seven Pairs and Thirteen Orphans are also recognized.
- Declare riichi only when a discard leaves the hand in tenpai.
- Win by tsumo or ron with at least one yaku.
- Chi, pon, open kan, closed kan, and added kan are supported.
- Each kan reveals another dora indicator and draws a replacement tile.
- Discard furiten, temporary furiten, and permanent riichi-pass furiten are enforced.
- Common yaku, dora, fu, han, and limit-hand point calculation are shown at the end of a hand.
- The alien evaluates waits, declares riichi, and can win by tsumo or ron.
- An empty wall produces an exhaustive draw and replays the same encounter.
- Defeat all four champions without losing a hand. One loss destroys Earth.

The first scoring set includes riichi, menzen tsumo, tanyao, yakuhai, pinfu, iipeikou, ryanpeikou, chiitoitsu, toitoi, sanshoku doujun, ittsuu, sanankou, sankantsu, honitsu, chinitsu, kokushi musou, and daisangen. Multi-round point settlement, red fives, ura-dora, ippatsu, chankan, and every rare local rule are not included yet.

## Open on macOS

Install [XcodeGen](https://github.com/yonaskolb/XcodeGen), then run:

```sh
cd ios/AlienMahjong
xcodegen generate
open AlienMahjong.xcodeproj
```

The app targets iOS 17 and uses SwiftUI. It has no network calls, ads, analytics, or collected data.
