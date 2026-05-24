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
  { id: "blush-candy-sparkle", name: "キャンディ頬", category: "チーク", src: "assets/morimori-photo-maker/blush-candy-sparkle.png", width: 42, x: 50, y: 55, z: 44 },
  { id: "blush-coral-stripe", name: "コーラル斜線", category: "チーク", src: "assets/morimori-photo-maker/blush-coral-stripe.png", width: 42, x: 50, y: 55, z: 44 },
  { id: "blush-purple-star", name: "紫スター", category: "チーク", src: "assets/morimori-photo-maker/blush-purple-star.png", width: 42, x: 50, y: 55, z: 44 },
  { id: "blush-heart-stamp", name: "ハート頬", category: "チーク", src: "assets/morimori-photo-maker/blush-heart-stamp.png", width: 42, x: 50, y: 55, z: 44 },
  { id: "blush-gold-freckles", name: "金そばかす", category: "チーク", src: "assets/morimori-photo-maker/blush-gold-freckles.png", width: 42, x: 50, y: 55, z: 44 },
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
  { id: "nail_pink_heart_pearl", name: "ピンクハートネイル", category: "ネイル", src: "assets/morimori-photo-maker/nail_pink_heart_pearl.png", width: 100, x: 50, y: 78, z: 64 },
  { id: "nail_lavender_holo_star", name: "ラベンダーホロネイル", category: "ネイル", src: "assets/morimori-photo-maker/nail_lavender_holo_star.png", width: 100, x: 50, y: 78, z: 64 },
  { id: "nail_red_black_gold", name: "赤黒ゴールドネイル", category: "ネイル", src: "assets/morimori-photo-maker/nail_red_black_gold.png", width: 100, x: 50, y: 82, z: 64 },
  { id: "cabaret_nail_01", name: "黒金ハートネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_01.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_02", name: "クリスタル姫ネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_02.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_03", name: "赤バラ女王ネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_03.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_04", name: "ピンクリボンネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_04.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_05", name: "紫ジュエルネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_05.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_06", name: "マリンブルーネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_06.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_07", name: "白花パールネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_07.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_08", name: "オレンジ宝石ネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_08.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_09", name: "透明シルバーネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_09.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_10", name: "深紅ゴールドネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_10.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_11", name: "ワインビジューネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_11.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_12", name: "黒レースネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_12.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_13", name: "ローズゴールドネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_13.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_14", name: "ピンクレオパネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_14.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_15", name: "白レースネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_15.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_16", name: "ブルーサファイアネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_16.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_17", name: "エメラルドネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_17.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_18", name: "紫オーロラネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_18.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_19", name: "金チェーンネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_19.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_20", name: "クリスタルロングネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_20.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_21", name: "ネオンピンクネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_21.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_22", name: "赤黒ヴァンパイアネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_22.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_23", name: "ミルキーパールネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_23.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_24", name: "マーメイドネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_24.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_25", name: "シャンパン四角ネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_25.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_26", name: "フューシャリボンネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_26.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_27", name: "紫ギャラクシーネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_27.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_28", name: "金レオパネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_28.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_29", name: "氷ブルーネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_29.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_30", name: "大粒ピンクネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_30.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_31", name: "桜クリスタルネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_31.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_32", name: "黒ダイヤネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_32.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_33", name: "白オパールネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_33.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_34", name: "ルビークロムネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_34.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_35", name: "虹オーロラネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_35.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_36", name: "ベージュパールチェーンネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_36.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_37", name: "ネオンイエローネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_37.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_38", name: "深緑エメラルドネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_38.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_39", name: "銀蝶ネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_39.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_40", name: "ホットピンクゼブラネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_40.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_41", name: "黒金ハートクイーンネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_41.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_42", name: "シャンパンヌードネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_42.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_43", name: "赤ローズチャームネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_43.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_44", name: "ピンク姫ストーンネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_44.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_45", name: "紫クロムジュエルネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_45.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_46", name: "青オーシャンネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_46.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_47", name: "白パールレースネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_47.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_48", name: "夕焼けグリッターネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_48.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_49", name: "ガラスクリスタルネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_49.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "cabaret_nail_50", name: "バーガンディ女王ネイル", category: "ネイル", src: "assets/morimori-photo-maker/packs/cabaret_nail_50.png", width: 100, x: 50, y: 82, z: 64, packId: "cabaretNailPack" },
  { id: "item_meerkat_plush", name: "ミーアキャットぬい", category: "アイテム", src: "assets/morimori-photo-maker/item_meerkat_plush.png", width: 32, x: 70, y: 72, z: 62 },
  { id: "item_heart_mirror", name: "ハートミラー", category: "アイテム", src: "assets/morimori-photo-maker/item_heart_mirror.png", width: 30, x: 28, y: 72, z: 62 },
  { id: "item_strawberry_parfait", name: "いちごパフェ", category: "アイテム", src: "assets/morimori-photo-maker/item_strawberry_parfait.png", width: 28, x: 72, y: 34, z: 62 },
  { id: "emotion_anger_mark", name: "怒りマーク", category: "感情", src: "assets/morimori-photo-maker/emotion_anger_mark.png", width: 22, x: 66, y: 28, z: 63 },
  { id: "emotion_tears_blue", name: "涙ぽろり", category: "感情", src: "assets/morimori-photo-maker/emotion_tears_blue.png", width: 28, x: 50, y: 51, z: 63 },
  { id: "emotion_sweat_surprise", name: "びっくり汗", category: "感情", src: "assets/morimori-photo-maker/emotion_sweat_surprise.png", width: 24, x: 66, y: 32, z: 63 },
  { id: "emotion_pack_anim_01", name: "動く怒りポップ", category: "感情", src: "assets/morimori-photo-maker/packs/emotion_pack_anim_01_animated.png", width: 26, x: 66, y: 28, z: 63, packId: "emotionPack" },
  { id: "emotion_pack_anim_02", name: "動く涙だばだば", category: "感情", src: "assets/morimori-photo-maker/packs/emotion_pack_anim_02_animated.png", width: 26, x: 42, y: 47, z: 63, packId: "emotionPack" },
  { id: "emotion_pack_anim_03", name: "動くショック爆発", category: "感情", src: "assets/morimori-photo-maker/packs/emotion_pack_anim_03_animated.png", width: 30, x: 68, y: 30, z: 63, packId: "emotionPack" },
  { id: "emotion_pack_anim_04", name: "動く鼓動ハート", category: "感情", src: "assets/morimori-photo-maker/packs/emotion_pack_anim_04_animated.png", width: 30, x: 66, y: 30, z: 63, packId: "emotionPack" },
  { id: "emotion_pack_anim_05", name: "動く汗ぽたぽた", category: "感情", src: "assets/morimori-photo-maker/packs/emotion_pack_anim_05_animated.png", width: 24, x: 66, y: 32, z: 63, packId: "emotionPack" },
  { id: "emotion_pack_anim_06", name: "動くぐるぐる混乱", category: "感情", src: "assets/morimori-photo-maker/packs/emotion_pack_anim_06_animated.png", width: 30, x: 32, y: 33, z: 63, packId: "emotionPack" },
  { id: "emotion_pack_anim_07", name: "動く燃えるイライラ", category: "感情", src: "assets/morimori-photo-maker/packs/emotion_pack_anim_07_animated.png", width: 32, x: 66, y: 34, z: 63, packId: "emotionPack" },
  { id: "emotion_pack_anim_08", name: "動くブルブル震え", category: "感情", src: "assets/morimori-photo-maker/packs/emotion_pack_anim_08_animated.png", width: 28, x: 50, y: 35, z: 63, packId: "emotionPack" },
  { id: "emotion_pack_anim_09", name: "動くきらめき興奮", category: "感情", src: "assets/morimori-photo-maker/packs/emotion_pack_anim_09_animated.png", width: 24, x: 32, y: 30, z: 63, packId: "emotionPack" },
  { id: "emotion_pack_anim_10", name: "動く危険ビリビリ", category: "感情", src: "assets/morimori-photo-maker/packs/emotion_pack_anim_10_animated.png", width: 30, x: 68, y: 34, z: 63, packId: "emotionPack" },
  { id: "emotion_pack_static_01", name: "もくもく考え中", category: "感情", src: "assets/morimori-photo-maker/packs/emotion_pack_static_01.png", width: 25, x: 30, y: 32, z: 63, packId: "emotionPack" },
  { id: "emotion_pack_static_02", name: "失恋ハート", category: "感情", src: "assets/morimori-photo-maker/packs/emotion_pack_static_02.png", width: 26, x: 66, y: 32, z: 63, packId: "emotionPack" },
  { id: "emotion_pack_static_03", name: "照れライン", category: "感情", src: "assets/morimori-photo-maker/packs/emotion_pack_static_03.png", width: 28, x: 50, y: 42, z: 63, packId: "emotionPack" },
  { id: "emotion_pack_static_04", name: "ふきだし雲", category: "感情", src: "assets/morimori-photo-maker/packs/emotion_pack_static_04.png", width: 27, x: 35, y: 30, z: 63, packId: "emotionPack" },
  { id: "emotion_pack_static_05", name: "びっくり爆発", category: "感情", src: "assets/morimori-photo-maker/packs/emotion_pack_static_05.png", width: 30, x: 68, y: 30, z: 63, packId: "emotionPack" },
  { id: "emotion_pack_static_06", name: "ハッピー花", category: "感情", src: "assets/morimori-photo-maker/packs/emotion_pack_static_06.png", width: 30, x: 30, y: 30, z: 63, packId: "emotionPack" },
  { id: "emotion_pack_static_07", name: "しょんぼり雨雲", category: "感情", src: "assets/morimori-photo-maker/packs/emotion_pack_static_07.png", width: 30, x: 65, y: 30, z: 63, packId: "emotionPack" },
  { id: "emotion_pack_static_08", name: "嫉妬オーラ", category: "感情", src: "assets/morimori-photo-maker/packs/emotion_pack_static_08.png", width: 30, x: 50, y: 32, z: 63, packId: "emotionPack" },
  { id: "emotion_pack_static_09", name: "緊張の汗", category: "感情", src: "assets/morimori-photo-maker/packs/emotion_pack_static_09.png", width: 28, x: 67, y: 38, z: 63, packId: "emotionPack" },
  { id: "emotion_pack_static_10", name: "王冠よろこび", category: "感情", src: "assets/morimori-photo-maker/packs/emotion_pack_static_10.png", width: 30, x: 50, y: 27, z: 63, packId: "emotionPack" },
  { id: "emotion_pack_static_11", name: "星ぐるぐる", category: "感情", src: "assets/morimori-photo-maker/packs/emotion_pack_static_11.png", width: 31, x: 50, y: 28, z: 63, packId: "emotionPack" },
  { id: "emotion_pack_static_12", name: "照れ雲", category: "感情", src: "assets/morimori-photo-maker/packs/emotion_pack_static_12.png", width: 28, x: 50, y: 42, z: 63, packId: "emotionPack" },
  { id: "emotion_pack_static_13", name: "ラブ矢ハート", category: "感情", src: "assets/morimori-photo-maker/packs/emotion_pack_static_13.png", width: 30, x: 66, y: 30, z: 63, packId: "emotionPack" },
  { id: "emotion_pack_static_14", name: "漫画インパクト", category: "感情", src: "assets/morimori-photo-maker/packs/emotion_pack_static_14.png", width: 28, x: 67, y: 34, z: 63, packId: "emotionPack" },
  { id: "emotion_pack_static_15", name: "ため息ふう", category: "感情", src: "assets/morimori-photo-maker/packs/emotion_pack_static_15.png", width: 28, x: 34, y: 56, z: 63, packId: "emotionPack" },
  { id: "halo", name: "キラ盛り", category: "フレーム", src: "assets/morimori-photo-maker/halo-sparkle.png", width: 90, x: 50, y: 49, z: 60 },
  { id: "burst", name: "派手フレーム", category: "フレーム", src: "assets/morimori-photo-maker/burst-frame.png", width: 100, x: 50, y: 50, z: 12 },
  { id: "burst-leopard-lightning", name: "豹柄ピカ盛り", category: "フレーム", src: "assets/morimori-photo-maker/burst-leopard-lightning.png", width: 100, x: 50, y: 50, z: 12 },
  { id: "kirakira", name: "キラキラMAX", category: "アニメ背景", src: "assets/morimori-photo-maker/kirakira-max-bg.gif", width: 100, x: 50, y: 50, z: 1, background: true },
  { id: "kirakira-pop", name: "ポップきらめき", category: "アニメ背景", src: "assets/morimori-photo-maker/kirakira-pop-bg.gif", width: 100, x: 50, y: 50, z: 1, background: true },
  { id: "pack1_hair_rose_wave", name: "ローズウェーブ", category: "髪型", src: "assets/morimori-photo-maker/packs/pack1_hair_rose_wave.png", width: 64, x: 50, y: 25, z: 30, packId: "morimoriPack1" },
  { id: "pack1_hair_caramel_halfup", name: "キャラメルハーフアップ", category: "髪型", src: "assets/morimori-photo-maker/packs/pack1_hair_caramel_halfup.png", width: 65, x: 50, y: 25, z: 30, packId: "morimoriPack1" },
  { id: "pack1_hair_black_ribbon_twin", name: "黒リボンツイン", category: "髪型", src: "assets/morimori-photo-maker/packs/pack1_hair_black_ribbon_twin.png", width: 66, x: 50, y: 25, z: 30, packId: "morimoriPack1" },
  { id: "pack1_hair_milk_tea_bob", name: "ミルクティーボブ", category: "髪型", src: "assets/morimori-photo-maker/packs/pack1_hair_milk_tea_bob.png", width: 58, x: 50, y: 25, z: 30, packId: "morimoriPack1" },
  { id: "pack1_hair_party_up", name: "夜会アップ", category: "髪型", src: "assets/morimori-photo-maker/packs/pack1_hair_party_up.png", width: 58, x: 50, y: 25, z: 30, packId: "morimoriPack1" },
  { id: "pack1_brows_soft_arch", name: "ふんわりアーチ", category: "まゆげ", src: "assets/morimori-photo-maker/packs/pack1_brows_soft_arch.png", width: 33, x: 50, y: 37, z: 45, packId: "morimoriPack1" },
  { id: "pack1_brows_glitter_gold", name: "金ラメ眉", category: "まゆげ", src: "assets/morimori-photo-maker/packs/pack1_brows_glitter_gold.png", width: 34, x: 50, y: 37, z: 45, packId: "morimoriPack1" },
  { id: "pack1_shadow_sakura_lame", name: "桜ラメシャドウ", category: "アイシャドウ", src: "assets/morimori-photo-maker/packs/pack1_shadow_sakura_lame.png", width: 43, x: 50, y: 43, z: 46, packId: "morimoriPack1" },
  { id: "pack1_shadow_brown_smoky", name: "ブラウン盛り", category: "アイシャドウ", src: "assets/morimori-photo-maker/packs/pack1_shadow_brown_smoky.png", width: 43, x: 50, y: 43, z: 46, packId: "morimoriPack1" },
  { id: "pack1_shadow_purple_cat", name: "紫キャット", category: "アイシャドウ", src: "assets/morimori-photo-maker/packs/pack1_shadow_purple_cat.png", width: 43, x: 50, y: 43, z: 46, packId: "morimoriPack1" },
  { id: "pack1_blush_peach_heart", name: "桃ハート頬", category: "チーク", src: "assets/morimori-photo-maker/packs/pack1_blush_peach_heart.png", width: 42, x: 50, y: 55, z: 44, packId: "morimoriPack1" },
  { id: "pack1_blush_rhinestone", name: "ラインストーン頬", category: "チーク", src: "assets/morimori-photo-maker/packs/pack1_blush_rhinestone.png", width: 42, x: 50, y: 55, z: 44, packId: "morimoriPack1" },
  { id: "pack1_lip_coral_gloss", name: "コーラルぷるん", category: "口紅", src: "assets/morimori-photo-maker/packs/pack1_lip_coral_gloss.png", width: 24, x: 50, y: 59, z: 47, packId: "morimoriPack1" },
  { id: "pack1_lip_berry_gloss", name: "ベリーグロス", category: "口紅", src: "assets/morimori-photo-maker/packs/pack1_lip_berry_gloss.png", width: 24, x: 50, y: 59, z: 47, packId: "morimoriPack1" },
  { id: "pack1_glasses_pink_rim", name: "ピンク細フレーム", category: "メガネ", src: "assets/morimori-photo-maker/packs/pack1_glasses_pink_rim.png", width: 43, x: 50, y: 43, z: 58, packId: "morimoriPack1" },
  { id: "pack1_glasses_clear_heart", name: "透明ハートメガネ", category: "メガネ", src: "assets/morimori-photo-maker/packs/pack1_glasses_clear_heart.png", width: 44, x: 50, y: 43, z: 58, packId: "morimoriPack1" },
  { id: "pack1_earring_pearl_drop", name: "パールドロップ", category: "イヤリング", src: "assets/morimori-photo-maker/packs/pack1_earring_pearl_drop.png", width: 54, x: 50, y: 50, z: 42, packId: "morimoriPack1" },
  { id: "pack1_earring_heart_chain", name: "ハートチェーン", category: "イヤリング", src: "assets/morimori-photo-maker/packs/pack1_earring_heart_chain.png", width: 54, x: 50, y: 50, z: 42, packId: "morimoriPack1" },
  { id: "pack1_nose_pink_gem", name: "ピンク宝石鼻ピ", category: "鼻ピアス", src: "assets/morimori-photo-maker/packs/pack1_nose_pink_gem.png", width: 9, x: 54, y: 51, z: 59, packId: "morimoriPack1" },
  { id: "pack1_frame_rose_pearl", name: "ローズパール枠", category: "フレーム", src: "assets/morimori-photo-maker/packs/pack1_frame_rose_pearl.png", width: 100, x: 50, y: 50, z: 12, packId: "morimoriPack1" },
  { id: "pack1_frame_lace_heart", name: "レースハート枠", category: "フレーム", src: "assets/morimori-photo-maker/packs/pack1_frame_lace_heart.png", width: 100, x: 50, y: 50, z: 12, packId: "morimoriPack1" },
  { id: "pack1_anim_pink_sparkle", name: "ピンク流れ星", category: "アニメ背景", src: "assets/morimori-photo-maker/packs/pack1_anim_pink_sparkle.gif", width: 100, x: 50, y: 50, z: 1, background: true, packId: "morimoriPack1" },
  { id: "pack1_anim_heart_bokeh", name: "ハートぼかし", category: "アニメ背景", src: "assets/morimori-photo-maker/packs/pack1_anim_heart_bokeh.gif", width: 100, x: 50, y: 50, z: 1, background: true, packId: "morimoriPack1" },
  { id: "pack1_part_tiara", name: "姫ティアラ", category: "髪飾り", src: "assets/morimori-photo-maker/packs/pack1_part_tiara.png", width: 36, x: 50, y: 18, z: 61, packId: "morimoriPack1" },
  { id: "pack1_part_ribbon_clip", name: "リボンクリップ", category: "髪飾り", src: "assets/morimori-photo-maker/packs/pack1_part_ribbon_clip.png", width: 30, x: 35, y: 28, z: 61, packId: "morimoriPack1" },
  { id: "pack1_part_pearl_chain", name: "パールチェーン", category: "髪飾り", src: "assets/morimori-photo-maker/packs/pack1_part_pearl_chain.png", width: 46, x: 50, y: 24, z: 61, packId: "morimoriPack1" },
  { id: "pack1_part_perfume", name: "香水きらめき", category: "アイテム", src: "assets/morimori-photo-maker/packs/pack1_part_perfume.png", width: 28, x: 30, y: 75, z: 62, packId: "morimoriPack1" },
  { id: "pack1_part_heart_balloon", name: "ハートバルーン", category: "アイテム", src: "assets/morimori-photo-maker/packs/pack1_part_heart_balloon.png", width: 42, x: 72, y: 28, z: 62, packId: "morimoriPack1" },
  { id: "pack1_part_glitter_tears", name: "きら涙", category: "アイテム", src: "assets/morimori-photo-maker/packs/pack1_part_glitter_tears.png", width: 20, x: 50, y: 49, z: 62, packId: "morimoriPack1" },
  { id: "pack1_part_star_sticker", name: "星ステッカー", category: "アイテム", src: "assets/morimori-photo-maker/packs/pack1_part_star_sticker.png", width: 34, x: 70, y: 35, z: 62, packId: "morimoriPack1" },
  { id: "serious_hair_straight_long", name: "清楚ストレート", category: "髪型", src: "assets/morimori-photo-maker/packs/serious_hair_straight_long.png", width: 60, x: 50, y: 25, z: 30, packId: "seriousPack" },
  { id: "yankee_hair_blonde_suji", name: "金髪スジ盛り", category: "髪型", src: "assets/morimori-photo-maker/packs/yankee_hair_blonde_suji.png", width: 66, x: 50, y: 25, z: 30, packId: "yankeeDecoPack" },
  { id: "yankee_hair_black_pompadour", name: "黒髪リーゼント", category: "髪型", src: "assets/morimori-photo-maker/packs/yankee_hair_black_pompadour.png", width: 58, x: 50, y: 25, z: 30, packId: "yankeeDecoPack" },
  { id: "yankee_hair_mesha_long", name: "メッシュロング", category: "髪型", src: "assets/morimori-photo-maker/packs/yankee_hair_mesha_long.png", width: 66, x: 50, y: 25, z: 30, packId: "yankeeDecoPack" },
  { id: "yankee_hair_high_side_pony", name: "高めサイドポニー", category: "髪型", src: "assets/morimori-photo-maker/packs/yankee_hair_high_side_pony.png", width: 66, x: 50, y: 25, z: 30, packId: "yankeeDecoPack" },
  { id: "yankee_hair_short_wolf", name: "強めウルフ", category: "髪型", src: "assets/morimori-photo-maker/packs/yankee_hair_short_wolf.png", width: 60, x: 50, y: 25, z: 30, packId: "yankeeDecoPack" },
  { id: "yankee_hair_accessory_sunglass_head", name: "頭サングラス", category: "髪飾り", src: "assets/morimori-photo-maker/packs/yankee_hair_accessory_sunglass_head.png", width: 42, x: 50, y: 18, z: 61, packId: "yankeeDecoPack" },
  { id: "yankee_hair_accessory_gold_pin", name: "金ピンセット", category: "髪飾り", src: "assets/morimori-photo-maker/packs/yankee_hair_accessory_gold_pin.png", width: 34, x: 35, y: 27, z: 61, packId: "yankeeDecoPack" },
  { id: "yankee_brows_sharp", name: "剃り込み眉", category: "まゆげ", src: "assets/morimori-photo-maker/packs/yankee_brows_sharp.png", width: 34, x: 50, y: 37, z: 45, packId: "yankeeDecoPack" },
  { id: "yankee_brows_thin_arch", name: "細つり眉", category: "まゆげ", src: "assets/morimori-photo-maker/packs/yankee_brows_thin_arch.png", width: 34, x: 50, y: 37, z: 45, packId: "yankeeDecoPack" },
  { id: "yankee_shadow_black_gold", name: "黒金シャドウ", category: "アイシャドウ", src: "assets/morimori-photo-maker/packs/yankee_shadow_black_gold.png", width: 43, x: 50, y: 43, z: 46, packId: "yankeeDecoPack" },
  { id: "yankee_shadow_red_flame", name: "赤炎シャドウ", category: "アイシャドウ", src: "assets/morimori-photo-maker/packs/yankee_shadow_red_flame.png", width: 43, x: 50, y: 43, z: 46, packId: "yankeeDecoPack" },
  { id: "yankee_blush_tan", name: "日焼けチーク", category: "チーク", src: "assets/morimori-photo-maker/packs/yankee_blush_tan.png", width: 42, x: 50, y: 55, z: 44, packId: "yankeeDecoPack" },
  { id: "yankee_blush_star_stamp", name: "星スタンプ頬", category: "チーク", src: "assets/morimori-photo-maker/packs/yankee_blush_star_stamp.png", width: 42, x: 50, y: 55, z: 44, packId: "yankeeDecoPack" },
  { id: "yankee_lip_deep_red", name: "深紅リップ", category: "口紅", src: "assets/morimori-photo-maker/packs/yankee_lip_deep_red.png", width: 24, x: 50, y: 59, z: 47, packId: "yankeeDecoPack" },
  { id: "yankee_lip_nude_gloss", name: "ヌーディグロス", category: "口紅", src: "assets/morimori-photo-maker/packs/yankee_lip_nude_gloss.png", width: 24, x: 50, y: 59, z: 47, packId: "yankeeDecoPack" },
  { id: "yankee_glasses_gold_sunglasses", name: "金縁サングラス", category: "メガネ", src: "assets/morimori-photo-maker/packs/yankee_glasses_gold_sunglasses.png", width: 46, x: 50, y: 43, z: 58, packId: "yankeeDecoPack" },
  { id: "yankee_glasses_clear_yellow", name: "黄クリアメガネ", category: "メガネ", src: "assets/morimori-photo-maker/packs/yankee_glasses_clear_yellow.png", width: 43, x: 50, y: 43, z: 58, packId: "yankeeDecoPack" },
  { id: "yankee_earring_gold_hoop", name: "金フープ", category: "イヤリング", src: "assets/morimori-photo-maker/packs/yankee_earring_gold_hoop.png", width: 54, x: 50, y: 50, z: 42, packId: "yankeeDecoPack" },
  { id: "yankee_earring_chain_cross", name: "十字チェーン", category: "イヤリング", src: "assets/morimori-photo-maker/packs/yankee_earring_chain_cross.png", width: 54, x: 50, y: 50, z: 42, packId: "yankeeDecoPack" },
  { id: "yankee_nose_gold_stud", name: "金鼻ピ", category: "鼻ピアス", src: "assets/morimori-photo-maker/packs/yankee_nose_gold_stud.png", width: 10, x: 54, y: 51, z: 59, packId: "yankeeDecoPack" },
  { id: "yankee_frame_leopard_gold", name: "豹柄ゴールド枠", category: "フレーム", src: "assets/morimori-photo-maker/packs/yankee_frame_leopard_gold.png", width: 100, x: 50, y: 50, z: 12, packId: "yankeeDecoPack" },
  { id: "yankee_frame_deco_truck", name: "デコトラ枠", category: "フレーム", src: "assets/morimori-photo-maker/packs/yankee_frame_deco_truck.png", width: 100, x: 50, y: 50, z: 12, packId: "yankeeDecoPack" },
  { id: "yankee_anim_neon_fire", name: "ネオン炎", category: "アニメ背景", src: "assets/morimori-photo-maker/packs/yankee_anim_neon_fire.gif", width: 100, x: 50, y: 50, z: 1, background: true, packId: "yankeeDecoPack" },
  { id: "yankee_anim_gold_flash", name: "金フラッシュ", category: "アニメ背景", src: "assets/morimori-photo-maker/packs/yankee_anim_gold_flash.gif", width: 100, x: 50, y: 50, z: 1, background: true, packId: "yankeeDecoPack" },
  { id: "yankee_part_gold_chain", name: "金チェーン", category: "アイテム", src: "assets/morimori-photo-maker/packs/yankee_part_gold_chain.png", width: 48, x: 50, y: 68, z: 62, packId: "yankeeDecoPack" },
  { id: "yankee_part_smoke", name: "スモーク", category: "アイテム", src: "assets/morimori-photo-maker/packs/yankee_part_smoke.png", width: 60, x: 50, y: 58, z: 62, packId: "yankeeDecoPack" },
  { id: "yankee_part_flame_sticker", name: "炎ステッカー", category: "アイテム", src: "assets/morimori-photo-maker/packs/yankee_part_flame_sticker.png", width: 38, x: 28, y: 70, z: 62, packId: "yankeeDecoPack" },
  { id: "yankee_part_kira_text", name: "夜露死苦プレート", category: "アイテム", src: "assets/morimori-photo-maker/packs/yankee_part_kira_text.png", width: 45, x: 50, y: 78, z: 62, packId: "yankeeDecoPack" },
  { id: "yankee_part_tiger", name: "虎ステッカー", category: "アイテム", src: "assets/morimori-photo-maker/packs/yankee_part_tiger.png", width: 34, x: 72, y: 30, z: 62, packId: "yankeeDecoPack" },
  { id: "yankee_part_chrome_heart", name: "クロームハート", category: "アイテム", src: "assets/morimori-photo-maker/packs/yankee_part_chrome_heart.png", width: 34, x: 30, y: 32, z: 62, packId: "yankeeDecoPack" },
  { id: "bubble_hair_one_length", name: "ワンレンロング", category: "髪型", src: "assets/morimori-photo-maker/packs/bubble_hair_one_length.png", width: 62, x: 50, y: 25, z: 30, packId: "bubbleDecoPack" },
  { id: "bubble_hair_sotohane_long", name: "外ハネロング", category: "髪型", src: "assets/morimori-photo-maker/packs/bubble_hair_sotohane_long.png", width: 64, x: 50, y: 25, z: 30, packId: "bubbleDecoPack" },
  { id: "bubble_hair_volume_perm", name: "ボリュームパーマ", category: "髪型", src: "assets/morimori-photo-maker/packs/bubble_hair_volume_perm.png", width: 66, x: 50, y: 25, z: 30, packId: "bubbleDecoPack" },
  { id: "bubble_hair_feather_bob", name: "フェザーボブ", category: "髪型", src: "assets/morimori-photo-maker/packs/bubble_hair_feather_bob.png", width: 58, x: 50, y: 25, z: 30, packId: "bubbleDecoPack" },
  { id: "bubble_hair_party_up", name: "バブル夜会巻き", category: "髪型", src: "assets/morimori-photo-maker/packs/bubble_hair_party_up.png", width: 58, x: 50, y: 25, z: 30, packId: "bubbleDecoPack" },
  { id: "bubble_hair_accessory_big_bow", name: "大きめサテンリボン", category: "髪飾り", src: "assets/morimori-photo-maker/packs/bubble_hair_accessory_big_bow.png", width: 34, x: 50, y: 20, z: 61, packId: "bubbleDecoPack" },
  { id: "bubble_hair_accessory_pearl_barrette", name: "真珠バレッタ", category: "髪飾り", src: "assets/morimori-photo-maker/packs/bubble_hair_accessory_pearl_barrette.png", width: 32, x: 35, y: 28, z: 61, packId: "bubbleDecoPack" },
  { id: "bubble_brows_bold_arch", name: "太アーチ眉", category: "まゆげ", src: "assets/morimori-photo-maker/packs/bubble_brows_bold_arch.png", width: 34, x: 50, y: 37, z: 45, packId: "bubbleDecoPack" },
  { id: "bubble_brows_soft_brown", name: "茶色ふと眉", category: "まゆげ", src: "assets/morimori-photo-maker/packs/bubble_brows_soft_brown.png", width: 34, x: 50, y: 37, z: 45, packId: "bubbleDecoPack" },
  { id: "bubble_shadow_blue_pearl", name: "ブルーパールシャドウ", category: "アイシャドウ", src: "assets/morimori-photo-maker/packs/bubble_shadow_blue_pearl.png", width: 43, x: 50, y: 43, z: 46, packId: "bubbleDecoPack" },
  { id: "bubble_shadow_gold_brown", name: "金ブラウンシャドウ", category: "アイシャドウ", src: "assets/morimori-photo-maker/packs/bubble_shadow_gold_brown.png", width: 43, x: 50, y: 43, z: 46, packId: "bubbleDecoPack" },
  { id: "bubble_blush_diagonal", name: "斜めチーク", category: "チーク", src: "assets/morimori-photo-maker/packs/bubble_blush_diagonal.png", width: 42, x: 50, y: 55, z: 44, packId: "bubbleDecoPack" },
  { id: "bubble_blush_rose", name: "ローズ頬", category: "チーク", src: "assets/morimori-photo-maker/packs/bubble_blush_rose.png", width: 42, x: 50, y: 55, z: 44, packId: "bubbleDecoPack" },
  { id: "bubble_lip_fuchsia", name: "フューシャリップ", category: "口紅", src: "assets/morimori-photo-maker/packs/bubble_lip_fuchsia.png", width: 24, x: 50, y: 59, z: 47, packId: "bubbleDecoPack" },
  { id: "bubble_lip_red_gloss", name: "赤グロス", category: "口紅", src: "assets/morimori-photo-maker/packs/bubble_lip_red_gloss.png", width: 24, x: 50, y: 59, z: 47, packId: "bubbleDecoPack" },
  { id: "bubble_glasses_gold_frame", name: "金縁メガネ", category: "メガネ", src: "assets/morimori-photo-maker/packs/bubble_glasses_gold_frame.png", width: 43, x: 50, y: 43, z: 58, packId: "bubbleDecoPack" },
  { id: "bubble_glasses_smoke_sunglasses", name: "スモークサングラス", category: "メガネ", src: "assets/morimori-photo-maker/packs/bubble_glasses_smoke_sunglasses.png", width: 46, x: 50, y: 43, z: 58, packId: "bubbleDecoPack" },
  { id: "bubble_earring_big_pearl", name: "大粒パール", category: "イヤリング", src: "assets/morimori-photo-maker/packs/bubble_earring_big_pearl.png", width: 52, x: 50, y: 50, z: 42, packId: "bubbleDecoPack" },
  { id: "bubble_earring_gold_disc", name: "ゴールドディスク", category: "イヤリング", src: "assets/morimori-photo-maker/packs/bubble_earring_gold_disc.png", width: 52, x: 50, y: 50, z: 42, packId: "bubbleDecoPack" },
  { id: "bubble_nose_tiny_diamond", name: "小粒ダイヤ鼻ピ", category: "鼻ピアス", src: "assets/morimori-photo-maker/packs/bubble_nose_tiny_diamond.png", width: 9, x: 54, y: 51, z: 59, packId: "bubbleDecoPack" },
  { id: "bubble_frame_disco_mirror", name: "ディスコミラー枠", category: "フレーム", src: "assets/morimori-photo-maker/packs/bubble_frame_disco_mirror.png", width: 100, x: 50, y: 50, z: 12, packId: "bubbleDecoPack" },
  { id: "bubble_frame_gold_city", name: "金夜景フレーム", category: "フレーム", src: "assets/morimori-photo-maker/packs/bubble_frame_gold_city.png", width: 100, x: 50, y: 50, z: 12, packId: "bubbleDecoPack" },
  { id: "bubble_anim_mirror_ball", name: "ミラーボール", category: "アニメ背景", src: "assets/morimori-photo-maker/packs/bubble_anim_mirror_ball.gif", width: 100, x: 50, y: 50, z: 1, background: true, packId: "bubbleDecoPack" },
  { id: "bubble_anim_city_sparkle", name: "夜景きらめき", category: "アニメ背景", src: "assets/morimori-photo-maker/packs/bubble_anim_city_sparkle.gif", width: 100, x: 50, y: 50, z: 1, background: true, packId: "bubbleDecoPack" },
  { id: "bubble_part_fan", name: "扇子", category: "アイテム", src: "assets/morimori-photo-maker/packs/bubble_part_fan.png", width: 34, x: 30, y: 72, z: 62, packId: "bubbleDecoPack" },
  { id: "bubble_part_champagne", name: "シャンパン", category: "アイテム", src: "assets/morimori-photo-maker/packs/bubble_part_champagne.png", width: 34, x: 72, y: 70, z: 62, packId: "bubbleDecoPack" },
  { id: "bubble_part_gold_chain", name: "太ゴールドチェーン", category: "アイテム", src: "assets/morimori-photo-maker/packs/bubble_part_gold_chain.png", width: 48, x: 50, y: 68, z: 62, packId: "bubbleDecoPack" },
  { id: "bubble_part_pearl_necklace", name: "パールネックレス", category: "アイテム", src: "assets/morimori-photo-maker/packs/bubble_part_pearl_necklace.png", width: 44, x: 50, y: 70, z: 62, packId: "bubbleDecoPack" },
  { id: "bubble_part_money_confetti", name: "札束コンフェティ", category: "アイテム", src: "assets/morimori-photo-maker/packs/bubble_part_money_confetti.png", width: 48, x: 50, y: 45, z: 62, packId: "bubbleDecoPack" },
  { id: "bubble_part_neon_lip", name: "ネオンリップ", category: "アイテム", src: "assets/morimori-photo-maker/packs/bubble_part_neon_lip.png", width: 32, x: 70, y: 34, z: 62, packId: "bubbleDecoPack" },
  { id: "pack2_hair_ash_layer", name: "アッシュレイヤー", category: "髪型", src: "assets/morimori-photo-maker/packs/pack2_hair_ash_layer.png", width: 62, x: 50, y: 25, z: 30, packId: "morimoriPack2" },
  { id: "pack2_hair_blue_black_long", name: "ブルーブラックロング", category: "髪型", src: "assets/morimori-photo-maker/packs/pack2_hair_blue_black_long.png", width: 62, x: 50, y: 25, z: 30, packId: "morimoriPack2" },
  { id: "pack2_hair_hime_wolf", name: "姫ウルフ", category: "髪型", src: "assets/morimori-photo-maker/packs/pack2_hair_hime_wolf.png", width: 63, x: 50, y: 25, z: 30, packId: "morimoriPack2" },
  { id: "pack2_hair_platinum_bob", name: "プラチナボブ", category: "髪型", src: "assets/morimori-photo-maker/packs/pack2_hair_platinum_bob.png", width: 58, x: 50, y: 25, z: 30, packId: "morimoriPack2" },
  { id: "pack2_hair_high_pony", name: "高めポニー", category: "髪型", src: "assets/morimori-photo-maker/packs/pack2_hair_high_pony.png", width: 62, x: 50, y: 25, z: 30, packId: "morimoriPack2" },
  { id: "pack2_brows_straight_k", name: "韓国ストレート眉", category: "まゆげ", src: "assets/morimori-photo-maker/packs/pack2_brows_straight_k.png", width: 34, x: 50, y: 37, z: 45, packId: "morimoriPack2" },
  { id: "pack2_brows_dark_mode", name: "黒強め眉", category: "まゆげ", src: "assets/morimori-photo-maker/packs/pack2_brows_dark_mode.png", width: 34, x: 50, y: 37, z: 45, packId: "morimoriPack2" },
  { id: "pack2_shadow_neon_blue", name: "ネオンブルー", category: "アイシャドウ", src: "assets/morimori-photo-maker/packs/pack2_shadow_neon_blue.png", width: 43, x: 50, y: 43, z: 46, packId: "morimoriPack2" },
  { id: "pack2_shadow_silver_cut", name: "シルバー切開", category: "アイシャドウ", src: "assets/morimori-photo-maker/packs/pack2_shadow_silver_cut.png", width: 43, x: 50, y: 43, z: 46, packId: "morimoriPack2" },
  { id: "pack2_shadow_devil_red", name: "小悪魔レッド", category: "アイシャドウ", src: "assets/morimori-photo-maker/packs/pack2_shadow_devil_red.png", width: 43, x: 50, y: 43, z: 46, packId: "morimoriPack2" },
  { id: "pack2_blush_under_eye", name: "目下チーク", category: "チーク", src: "assets/morimori-photo-maker/packs/pack2_blush_under_eye.png", width: 42, x: 50, y: 52, z: 44, packId: "morimoriPack2" },
  { id: "pack2_blush_cool_pink", name: "青みピンク頬", category: "チーク", src: "assets/morimori-photo-maker/packs/pack2_blush_cool_pink.png", width: 42, x: 50, y: 55, z: 44, packId: "morimoriPack2" },
  { id: "pack2_lip_mauve", name: "モーヴリップ", category: "口紅", src: "assets/morimori-photo-maker/packs/pack2_lip_mauve.png", width: 24, x: 50, y: 59, z: 47, packId: "morimoriPack2" },
  { id: "pack2_lip_cherry_tint", name: "チェリーティント", category: "口紅", src: "assets/morimori-photo-maker/packs/pack2_lip_cherry_tint.png", width: 24, x: 50, y: 59, z: 47, packId: "morimoriPack2" },
  { id: "pack2_glasses_silver_thin", name: "銀細メガネ", category: "メガネ", src: "assets/morimori-photo-maker/packs/pack2_glasses_silver_thin.png", width: 43, x: 50, y: 43, z: 58, packId: "morimoriPack2" },
  { id: "pack2_glasses_y2k_shield", name: "Y2Kシールド", category: "メガネ", src: "assets/morimori-photo-maker/packs/pack2_glasses_y2k_shield.png", width: 46, x: 50, y: 43, z: 58, packId: "morimoriPack2" },
  { id: "pack2_earring_chrome_hoop", name: "クロームフープ", category: "イヤリング", src: "assets/morimori-photo-maker/packs/pack2_earring_chrome_hoop.png", width: 54, x: 50, y: 50, z: 42, packId: "morimoriPack2" },
  { id: "pack2_earring_black_heart", name: "黒ハートピアス", category: "イヤリング", src: "assets/morimori-photo-maker/packs/pack2_earring_black_heart.png", width: 54, x: 50, y: 50, z: 42, packId: "morimoriPack2" },
  { id: "pack2_nose_chain", name: "鼻チェーン", category: "鼻ピアス", src: "assets/morimori-photo-maker/packs/pack2_nose_chain.png", width: 15, x: 51, y: 51, z: 59, packId: "morimoriPack2" },
  { id: "pack2_frame_neon_city", name: "ネオンシティ枠", category: "フレーム", src: "assets/morimori-photo-maker/packs/pack2_frame_neon_city.png", width: 100, x: 50, y: 50, z: 12, packId: "morimoriPack2" },
  { id: "pack2_frame_chrome_stars", name: "クロームスター枠", category: "フレーム", src: "assets/morimori-photo-maker/packs/pack2_frame_chrome_stars.png", width: 100, x: 50, y: 50, z: 12, packId: "morimoriPack2" },
  { id: "pack2_anim_neon_rain", name: "ネオン雨", category: "アニメ背景", src: "assets/morimori-photo-maker/packs/pack2_anim_neon_rain.gif", width: 100, x: 50, y: 50, z: 1, background: true, packId: "morimoriPack2" },
  { id: "pack2_anim_chrome_flash", name: "クローム閃光", category: "アニメ背景", src: "assets/morimori-photo-maker/packs/pack2_anim_chrome_flash.gif", width: 100, x: 50, y: 50, z: 1, background: true, packId: "morimoriPack2" },
  { id: "pack2_part_cat_ears", name: "小悪魔猫耳", category: "髪飾り", src: "assets/morimori-photo-maker/packs/pack2_part_cat_ears.png", width: 42, x: 50, y: 20, z: 61, packId: "morimoriPack2" },
  { id: "pack2_part_black_ribbon", name: "黒リボン", category: "髪飾り", src: "assets/morimori-photo-maker/packs/pack2_part_black_ribbon.png", width: 30, x: 35, y: 27, z: 61, packId: "morimoriPack2" },
  { id: "pack2_part_chrome_crown", name: "クローム王冠", category: "髪飾り", src: "assets/morimori-photo-maker/packs/pack2_part_chrome_crown.png", width: 34, x: 50, y: 18, z: 61, packId: "morimoriPack2" },
  { id: "pack2_part_music_note", name: "音符きらめき", category: "アイテム", src: "assets/morimori-photo-maker/packs/pack2_part_music_note.png", width: 34, x: 72, y: 34, z: 62, packId: "morimoriPack2" },
  { id: "pack2_part_moon_charm", name: "月チャーム", category: "アイテム", src: "assets/morimori-photo-maker/packs/pack2_part_moon_charm.png", width: 28, x: 30, y: 30, z: 62, packId: "morimoriPack2" },
  { id: "pack2_part_glossy_stars", name: "ぷっくり星", category: "アイテム", src: "assets/morimori-photo-maker/packs/pack2_part_glossy_stars.png", width: 34, x: 70, y: 70, z: 62, packId: "morimoriPack2" },
  { id: "pack2_part_light_streak", name: "光ライン", category: "アイテム", src: "assets/morimori-photo-maker/packs/pack2_part_light_streak.png", width: 55, x: 50, y: 45, z: 62, packId: "morimoriPack2" },
  { id: "serious_hair_one_curl", name: "内巻きワンカール", category: "髪型", src: "assets/morimori-photo-maker/packs/serious_hair_one_curl.png", width: 60, x: 50, y: 25, z: 30, packId: "seriousPack" },
  { id: "serious_hair_layer_medium", name: "レイヤーミディアム", category: "髪型", src: "assets/morimori-photo-maker/packs/serious_hair_layer_medium.png", width: 60, x: 50, y: 25, z: 30, packId: "seriousPack" },
  { id: "serious_hair_short_bob", name: "ショートボブ", category: "髪型", src: "assets/morimori-photo-maker/packs/serious_hair_short_bob.png", width: 56, x: 50, y: 25, z: 30, packId: "seriousPack" },
  { id: "serious_hair_center_part", name: "センターパート", category: "髪型", src: "assets/morimori-photo-maker/packs/serious_hair_center_part.png", width: 60, x: 50, y: 25, z: 30, packId: "seriousPack" },
  { id: "serious_hair_low_pony", name: "低めポニー", category: "髪型", src: "assets/morimori-photo-maker/packs/serious_hair_low_pony.png", width: 58, x: 50, y: 25, z: 30, packId: "seriousPack" },
  { id: "serious_hair_halfup", name: "控えめハーフアップ", category: "髪型", src: "assets/morimori-photo-maker/packs/serious_hair_halfup.png", width: 60, x: 50, y: 25, z: 30, packId: "seriousPack" },
  { id: "serious_hair_natural_wolf", name: "ナチュラルウルフ", category: "髪型", src: "assets/morimori-photo-maker/packs/serious_hair_natural_wolf.png", width: 58, x: 50, y: 25, z: 30, packId: "seriousPack" },
  { id: "serious_hair_bang_sheer", name: "シースルーバング", category: "髪型", src: "assets/morimori-photo-maker/packs/serious_hair_bang_sheer.png", width: 60, x: 50, y: 25, z: 30, packId: "seriousPack" },
  { id: "serious_hair_no_bang", name: "前髪なしロング", category: "髪型", src: "assets/morimori-photo-maker/packs/serious_hair_no_bang.png", width: 60, x: 50, y: 25, z: 30, packId: "seriousPack" },
  { id: "serious_brows_natural", name: "自然眉", category: "まゆげ", src: "assets/morimori-photo-maker/packs/serious_brows_natural.png", width: 33, x: 50, y: 37, z: 45, packId: "seriousPack" },
  { id: "serious_brows_straight", name: "きちんと眉", category: "まゆげ", src: "assets/morimori-photo-maker/packs/serious_brows_straight.png", width: 33, x: 50, y: 37, z: 45, packId: "seriousPack" },
  { id: "serious_brows_soft", name: "やわらか眉", category: "まゆげ", src: "assets/morimori-photo-maker/packs/serious_brows_soft.png", width: 33, x: 50, y: 37, z: 45, packId: "seriousPack" },
  { id: "serious_shadow_beige", name: "ベージュシャドウ", category: "アイシャドウ", src: "assets/morimori-photo-maker/packs/serious_shadow_beige.png", width: 42, x: 50, y: 43, z: 46, packId: "seriousPack" },
  { id: "serious_shadow_brown", name: "ブラウンシャドウ", category: "アイシャドウ", src: "assets/morimori-photo-maker/packs/serious_shadow_brown.png", width: 42, x: 50, y: 43, z: 46, packId: "seriousPack" },
  { id: "serious_shadow_pink_brown", name: "ピンクブラウン", category: "アイシャドウ", src: "assets/morimori-photo-maker/packs/serious_shadow_pink_brown.png", width: 42, x: 50, y: 43, z: 46, packId: "seriousPack" },
  { id: "serious_blush_natural", name: "自然チーク", category: "チーク", src: "assets/morimori-photo-maker/packs/serious_blush_natural.png", width: 42, x: 50, y: 55, z: 44, packId: "seriousPack" },
  { id: "serious_blush_soft_peach", name: "薄桃チーク", category: "チーク", src: "assets/morimori-photo-maker/packs/serious_blush_soft_peach.png", width: 42, x: 50, y: 55, z: 44, packId: "seriousPack" },
  { id: "serious_lip_nude_pink", name: "ヌードピンク", category: "口紅", src: "assets/morimori-photo-maker/packs/serious_lip_nude_pink.png", width: 24, x: 50, y: 59, z: 47, packId: "seriousPack" },
  { id: "serious_lip_calm_red", name: "落ち着きレッド", category: "口紅", src: "assets/morimori-photo-maker/packs/serious_lip_calm_red.png", width: 24, x: 50, y: 59, z: 47, packId: "seriousPack" },
  { id: "serious_glasses_round", name: "丸メガネ", category: "メガネ", src: "assets/morimori-photo-maker/packs/serious_glasses_round.png", width: 43, x: 50, y: 43, z: 58, packId: "seriousPack" },
  { id: "serious_glasses_square", name: "スクエアメガネ", category: "メガネ", src: "assets/morimori-photo-maker/packs/serious_glasses_square.png", width: 43, x: 50, y: 43, z: 58, packId: "seriousPack" },
  { id: "serious_glasses_brown", name: "ブラウン細メガネ", category: "メガネ", src: "assets/morimori-photo-maker/packs/serious_glasses_brown.png", width: 43, x: 50, y: 43, z: 58, packId: "seriousPack" },
  { id: "serious_background_office", name: "明るいオフィス", category: "フレーム", src: "assets/morimori-photo-maker/packs/serious_background_office.png", width: 100, x: 50, y: 50, z: 12, packId: "seriousPack" },
  { id: "serious_background_white", name: "白背景", category: "フレーム", src: "assets/morimori-photo-maker/packs/serious_background_white.png", width: 100, x: 50, y: 50, z: 12, packId: "seriousPack" },
  { id: "serious_background_beige", name: "ベージュ背景", category: "フレーム", src: "assets/morimori-photo-maker/packs/serious_background_beige.png", width: 100, x: 50, y: 50, z: 12, packId: "seriousPack" },
  { id: "serious_background_school", name: "教室背景", category: "フレーム", src: "assets/morimori-photo-maker/packs/serious_background_school.png", width: 100, x: 50, y: 50, z: 12, packId: "seriousPack" },
  { id: "serious_background_cafe", name: "カフェ背景", category: "フレーム", src: "assets/morimori-photo-maker/packs/serious_background_cafe.png", width: 100, x: 50, y: 50, z: 12, packId: "seriousPack" },
  { id: "serious_background_library", name: "図書館背景", category: "フレーム", src: "assets/morimori-photo-maker/packs/serious_background_library.png", width: 100, x: 50, y: 50, z: 12, packId: "seriousPack" },
  { id: "serious_background_greenery", name: "自然光グリーン背景", category: "フレーム", src: "assets/morimori-photo-maker/packs/serious_background_greenery.png", width: 100, x: 50, y: 50, z: 12, packId: "seriousPack" },
  { id: "serious_frame_simple_white", name: "白シンプル枠", category: "フレーム", src: "assets/morimori-photo-maker/packs/serious_frame_simple_white.png", width: 100, x: 50, y: 50, z: 12, packId: "seriousPack" },
  { id: "serious_frame_soft_pink", name: "薄桃シンプル枠", category: "フレーム", src: "assets/morimori-photo-maker/packs/serious_frame_soft_pink.png", width: 100, x: 50, y: 50, z: 12, packId: "seriousPack" },
  { id: "serious_part_resume_frame", name: "証明写真風枠", category: "フレーム", src: "assets/morimori-photo-maker/packs/serious_part_resume_frame.png", width: 100, x: 50, y: 50, z: 12, packId: "seriousPack" },
  { id: "serious_part_hairpin", name: "細ヘアピン", category: "髪飾り", src: "assets/morimori-photo-maker/packs/serious_part_hairpin.png", width: 28, x: 35, y: 25, z: 61, packId: "seriousPack" },
  { id: "serious_part_small_ribbon", name: "小リボン", category: "髪飾り", src: "assets/morimori-photo-maker/packs/serious_part_small_ribbon.png", width: 28, x: 62, y: 24, z: 61, packId: "seriousPack" },
  { id: "serious_part_school_ribbon", name: "制服リボン", category: "髪飾り", src: "assets/morimori-photo-maker/packs/serious_part_school_ribbon.png", width: 30, x: 50, y: 63, z: 61, packId: "seriousPack" },
  { id: "serious_part_simple_tiara", name: "控えめティアラ", category: "髪飾り", src: "assets/morimori-photo-maker/packs/serious_part_simple_tiara.png", width: 32, x: 50, y: 18, z: 61, packId: "seriousPack" },
  { id: "serious_part_light", name: "自然光", category: "アイテム", src: "assets/morimori-photo-maker/packs/serious_part_light.png", width: 90, x: 50, y: 45, z: 62, packId: "seriousPack" },
  { id: "serious_part_soft_sparkle", name: "控えめきらめき", category: "アイテム", src: "assets/morimori-photo-maker/packs/serious_part_soft_sparkle.png", width: 90, x: 50, y: 50, z: 62, packId: "seriousPack" },
  { id: "serious_part_name_plate", name: "名札風プレート", category: "アイテム", src: "assets/morimori-photo-maker/packs/serious_part_name_plate.png", width: 26, x: 68, y: 64, z: 62, packId: "seriousPack" },
  { id: "serious_part_flower", name: "小花", category: "アイテム", src: "assets/morimori-photo-maker/packs/serious_part_flower.png", width: 24, x: 32, y: 30, z: 62, packId: "seriousPack" },
  { id: "serious_part_book", name: "本アイコン", category: "アイテム", src: "assets/morimori-photo-maker/packs/serious_part_book.png", width: 24, x: 30, y: 74, z: 62, packId: "seriousPack" },
  { id: "serious_part_laptop", name: "PCアイコン", category: "アイテム", src: "assets/morimori-photo-maker/packs/serious_part_laptop.png", width: 28, x: 70, y: 74, z: 62, packId: "seriousPack" },
  { id: "serious_part_pencil", name: "ペンアイコン", category: "アイテム", src: "assets/morimori-photo-maker/packs/serious_part_pencil.png", width: 24, x: 68, y: 30, z: 62, packId: "seriousPack" },
  { id: "serious_part_cardigan", name: "肩掛け風", category: "アイテム", src: "assets/morimori-photo-maker/packs/serious_part_cardigan.png", width: 58, x: 50, y: 73, z: 62, packId: "seriousPack" },
  { id: "serious_part_soft_shadow", name: "自然影", category: "アイテム", src: "assets/morimori-photo-maker/packs/serious_part_soft_shadow.png", width: 62, x: 50, y: 62, z: 62, packId: "seriousPack" },
  { id: "serious_part_eye_light", name: "瞳ハイライト", category: "アイテム", src: "assets/morimori-photo-maker/packs/serious_part_eye_light.png", width: 30, x: 50, y: 43, z: 62, packId: "seriousPack" },
  { id: "serious_part_skin_glow", name: "肌つや", category: "アイテム", src: "assets/morimori-photo-maker/packs/serious_part_skin_glow.png", width: 60, x: 50, y: 48, z: 62, packId: "seriousPack" },
  { id: "serious_part_clean_filter", name: "清潔感フィルター", category: "アイテム", src: "assets/morimori-photo-maker/packs/serious_part_clean_filter.png", width: 100, x: 50, y: 50, z: 62, packId: "seriousPack" },
  { id: "serious_part_glass_reflection", name: "メガネ反射", category: "アイテム", src: "assets/morimori-photo-maker/packs/serious_part_glass_reflection.png", width: 42, x: 50, y: 43, z: 62, packId: "seriousPack" },
  { id: "pack1_lashes_doll_volume", name: "盛りドールつけま", category: "つけまつげ", src: "assets/morimori-photo-maker/packs/pack1_lashes_doll_volume.png", width: 40, x: 50, y: 43, z: 48, packId: "morimoriPack1" },
  { id: "pack1_lashes_pink_rhinestone", name: "ピンクきらつけま", category: "つけまつげ", src: "assets/morimori-photo-maker/packs/pack1_lashes_pink_rhinestone.png", width: 40, x: 50, y: 43, z: 48, packId: "morimoriPack1" },
  { id: "serious_lashes_natural_office", name: "自然オフィスつけま", category: "つけまつげ", src: "assets/morimori-photo-maker/packs/serious_lashes_natural_office.png", width: 39, x: 50, y: 43, z: 48, packId: "seriousPack" },
  { id: "serious_lashes_brown_half", name: "ブラウン半つけま", category: "つけまつげ", src: "assets/morimori-photo-maker/packs/serious_lashes_brown_half.png", width: 39, x: 50, y: 43, z: 48, packId: "seriousPack" },
  { id: "yankee_lashes_spiky_wing", name: "強めハネつけま", category: "つけまつげ", src: "assets/morimori-photo-maker/packs/yankee_lashes_spiky_wing.png", width: 41, x: 50, y: 43, z: 48, packId: "yankeeDecoPack" },
  { id: "yankee_lashes_black_gold", name: "黒金つけま", category: "つけまつげ", src: "assets/morimori-photo-maker/packs/yankee_lashes_black_gold.png", width: 41, x: 50, y: 43, z: 48, packId: "yankeeDecoPack" },
  { id: "bubble_lashes_fan_glam", name: "バブル扇つけま", category: "つけまつげ", src: "assets/morimori-photo-maker/packs/bubble_lashes_fan_glam.png", width: 41, x: 50, y: 43, z: 48, packId: "bubbleDecoPack" },
  { id: "bubble_lashes_pearl_glam", name: "パール盛りつけま", category: "つけまつげ", src: "assets/morimori-photo-maker/packs/bubble_lashes_pearl_glam.png", width: 41, x: 50, y: 43, z: 48, packId: "bubbleDecoPack" },
  { id: "korean_lashes_idol_natural", name: "韓国アイドルつけま", category: "つけまつげ", src: "assets/morimori-photo-maker/packs/korean_lashes_idol_natural.png", width: 39, x: 50, y: 43, z: 48, packId: "koreanHairPack" },
  { id: "korean_lashes_soft_cat", name: "韓国キャットつけま", category: "つけまつげ", src: "assets/morimori-photo-maker/packs/korean_lashes_soft_cat.png", width: 39, x: 50, y: 43, z: 48, packId: "koreanHairPack" },
  { id: "hime_lashes_pearl_doll", name: "姫パールドールつけま", category: "つけまつげ", src: "assets/morimori-photo-maker/packs/hime_lashes_pearl_doll.png", width: 41, x: 50, y: 43, z: 48, packId: "himeMoriPack" },
  { id: "hime_lashes_royal_wing", name: "姫ロイヤルつけま", category: "つけまつげ", src: "assets/morimori-photo-maker/packs/hime_lashes_royal_wing.png", width: 41, x: 50, y: 43, z: 48, packId: "himeMoriPack" },
  { id: "kyun_neko_plush_milk", name: "ミルクねこ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/kyun_neko_plush_milk.png", width: 34, x: 32, y: 72, z: 62, packId: "kyunNekoPack" },
  { id: "kyun_neko_plush_sakura", name: "さくらねこ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/kyun_neko_plush_sakura.png", width: 34, x: 70, y: 72, z: 62, packId: "kyunNekoPack" },
  { id: "kyun_neko_plush_calico", name: "みけねこ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/kyun_neko_plush_calico.png", width: 34, x: 30, y: 72, z: 62, packId: "kyunNekoPack" },
  { id: "kyun_neko_plush_black", name: "くろねこ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/kyun_neko_plush_black.png", width: 34, x: 72, y: 70, z: 62, packId: "kyunNekoPack" },
  { id: "kyun_neko_plush_ribbon", name: "リボンねこ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/kyun_neko_plush_ribbon.png", width: 34, x: 34, y: 74, z: 62, packId: "kyunNekoPack" },
  { id: "kyun_neko_plush_sleepy", name: "ねむねこ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/kyun_neko_plush_sleepy.png", width: 34, x: 68, y: 74, z: 62, packId: "kyunNekoPack" },
  { id: "kyun_neko_plush_angel", name: "天使ねこ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/kyun_neko_plush_angel.png", width: 34, x: 30, y: 70, z: 62, packId: "kyunNekoPack" },
  { id: "kyun_neko_plush_strawberry", name: "いちごねこ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/kyun_neko_plush_strawberry.png", width: 34, x: 70, y: 70, z: 62, packId: "kyunNekoPack" },
  { id: "kyun_neko_plush_star", name: "星ねこ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/kyun_neko_plush_star.png", width: 34, x: 32, y: 70, z: 62, packId: "kyunNekoPack" },
  { id: "kyun_neko_plush_tiny", name: "ちびねこ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/kyun_neko_plush_tiny.png", width: 30, x: 70, y: 74, z: 62, packId: "kyunNekoPack" },
  { id: "mofu_usa_plush_white", name: "しろうさ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/mofu_usa_plush_white.png", width: 34, x: 32, y: 72, z: 62, packId: "mofuUsaPack" },
  { id: "mofu_usa_plush_pink", name: "ももいろうさ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/mofu_usa_plush_pink.png", width: 34, x: 70, y: 72, z: 62, packId: "mofuUsaPack" },
  { id: "mofu_usa_plush_lop", name: "たれ耳うさ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/mofu_usa_plush_lop.png", width: 34, x: 34, y: 72, z: 62, packId: "mofuUsaPack" },
  { id: "mofu_usa_plush_gray", name: "グレーうさ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/mofu_usa_plush_gray.png", width: 34, x: 68, y: 72, z: 62, packId: "mofuUsaPack" },
  { id: "mofu_usa_plush_ribbon", name: "リボンうさ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/mofu_usa_plush_ribbon.png", width: 34, x: 32, y: 72, z: 62, packId: "mofuUsaPack" },
  { id: "mofu_usa_plush_strawberry", name: "いちごうさ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/mofu_usa_plush_strawberry.png", width: 34, x: 70, y: 72, z: 62, packId: "mofuUsaPack" },
  { id: "mofu_usa_plush_sleepy", name: "ねむうさ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/mofu_usa_plush_sleepy.png", width: 34, x: 32, y: 74, z: 62, packId: "mofuUsaPack" },
  { id: "mofu_usa_plush_angel", name: "天使うさ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/mofu_usa_plush_angel.png", width: 34, x: 70, y: 70, z: 62, packId: "mofuUsaPack" },
  { id: "mofu_usa_plush_star", name: "星うさ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/mofu_usa_plush_star.png", width: 34, x: 32, y: 70, z: 62, packId: "mofuUsaPack" },
  { id: "mofu_usa_plush_tiny", name: "ちびうさ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/mofu_usa_plush_tiny.png", width: 30, x: 70, y: 74, z: 62, packId: "mofuUsaPack" },
  { id: "korean_hair_c_curl_long", name: "韓国Cカールロング", category: "髪型", src: "assets/morimori-photo-maker/packs/korean_hair_c_curl_long.png", width: 62, x: 50, y: 25, z: 30, packId: "koreanHairPack" },
  { id: "korean_hair_tassel_bob", name: "韓国タッセルボブ", category: "髪型", src: "assets/morimori-photo-maker/packs/korean_hair_tassel_bob.png", width: 58, x: 50, y: 25, z: 30, packId: "koreanHairPack" },
  { id: "korean_hair_glass_long", name: "韓国グラスロング", category: "髪型", src: "assets/morimori-photo-maker/packs/korean_hair_glass_long.png", width: 62, x: 50, y: 25, z: 30, packId: "koreanHairPack" },
  { id: "korean_hair_milktea_wave", name: "韓国ミルクティーウェーブ", category: "髪型", src: "assets/morimori-photo-maker/packs/korean_hair_milktea_wave.png", width: 62, x: 50, y: 25, z: 30, packId: "koreanHairPack" },
  { id: "korean_hair_ash_short_bob", name: "韓国アッシュショート", category: "髪型", src: "assets/morimori-photo-maker/packs/korean_hair_ash_short_bob.png", width: 58, x: 50, y: 25, z: 30, packId: "koreanHairPack" },
  { id: "korean_hair_hush_wolf", name: "韓国ハッシュウルフ", category: "髪型", src: "assets/morimori-photo-maker/packs/korean_hair_hush_wolf.png", width: 60, x: 50, y: 25, z: 30, packId: "koreanHairPack" },
  { id: "korean_hair_high_pony", name: "韓国ハイポニー", category: "髪型", src: "assets/morimori-photo-maker/packs/korean_hair_high_pony.png", width: 58, x: 50, y: 25, z: 30, packId: "koreanHairPack" },
  { id: "korean_hair_low_bun", name: "韓国ロウバン", category: "髪型", src: "assets/morimori-photo-maker/packs/korean_hair_low_bun.png", width: 56, x: 50, y: 25, z: 30, packId: "koreanHairPack" },
  { id: "korean_hair_halfup_wave", name: "韓国ハーフアップ", category: "髪型", src: "assets/morimori-photo-maker/packs/korean_hair_halfup_wave.png", width: 62, x: 50, y: 25, z: 30, packId: "koreanHairPack" },
  { id: "korean_hair_low_twintail", name: "韓国ローツイン", category: "髪型", src: "assets/morimori-photo-maker/packs/korean_hair_low_twintail.png", width: 62, x: 50, y: 25, z: 30, packId: "koreanHairPack" },
  { id: "kfashion_glasses_clear_round", name: "韓国クリア丸メガネ", category: "メガネ", src: "assets/morimori-photo-maker/packs/kfashion_glasses_clear_round.png", width: 43, x: 50, y: 43, z: 58, packId: "koreanFashionPack" },
  { id: "kfashion_glasses_metal_square", name: "韓国メタル四角メガネ", category: "メガネ", src: "assets/morimori-photo-maker/packs/kfashion_glasses_metal_square.png", width: 43, x: 50, y: 43, z: 58, packId: "koreanFashionPack" },
  { id: "kfashion_glasses_gray_tint", name: "韓国グレーティント", category: "メガネ", src: "assets/morimori-photo-maker/packs/kfashion_glasses_gray_tint.png", width: 43, x: 50, y: 43, z: 58, packId: "koreanFashionPack" },
  { id: "kfashion_glasses_pearl_chain", name: "韓国パール丸メガネ", category: "メガネ", src: "assets/morimori-photo-maker/packs/kfashion_glasses_pearl_chain.png", width: 43, x: 50, y: 43, z: 58, packId: "koreanFashionPack" },
  { id: "hime_hair_blonde_curl", name: "姫ブロンド盛り", category: "髪型", src: "assets/morimori-photo-maker/packs/hime_hair_blonde_curl.png", width: 66, x: 50, y: 25, z: 30, packId: "himeMoriPack" },
  { id: "hime_hair_rose_halfup", name: "姫ローズハーフ", category: "髪型", src: "assets/morimori-photo-maker/packs/hime_hair_rose_halfup.png", width: 64, x: 50, y: 25, z: 30, packId: "himeMoriPack" },
  { id: "hime_hair_black_himecut", name: "黒髪姫カット", category: "髪型", src: "assets/morimori-photo-maker/packs/hime_hair_black_himecut.png", width: 62, x: 50, y: 25, z: 30, packId: "himeMoriPack" },
  { id: "hime_hair_pink_high_pony", name: "姫ピンクポニー", category: "髪型", src: "assets/morimori-photo-maker/packs/hime_hair_pink_high_pony.png", width: 62, x: 50, y: 25, z: 30, packId: "himeMoriPack" },
  { id: "hime_hair_milktea_bob", name: "姫ミルクティーボブ", category: "髪型", src: "assets/morimori-photo-maker/packs/hime_hair_milktea_bob.png", width: 58, x: 50, y: 25, z: 30, packId: "himeMoriPack" },
  { id: "hime_hair_tiara_heart", name: "ハートティアラ", category: "髪飾り", src: "assets/morimori-photo-maker/packs/hime_hair_tiara_heart.png", width: 34, x: 50, y: 18, z: 61, packId: "himeMoriPack" },
  { id: "hime_hair_gold_crown", name: "小さな王冠", category: "髪飾り", src: "assets/morimori-photo-maker/packs/hime_hair_gold_crown.png", width: 30, x: 58, y: 17, z: 61, packId: "himeMoriPack" },
  { id: "hime_hair_satin_bow", name: "姫サテンリボン", category: "髪飾り", src: "assets/morimori-photo-maker/packs/hime_hair_satin_bow.png", width: 34, x: 37, y: 23, z: 61, packId: "himeMoriPack" },
  { id: "hime_hair_lace_headband", name: "レースカチューシャ", category: "髪飾り", src: "assets/morimori-photo-maker/packs/hime_hair_lace_headband.png", width: 42, x: 50, y: 21, z: 61, packId: "himeMoriPack" },
  { id: "hime_hair_chain_heart", name: "ハート髪チェーン", category: "髪飾り", src: "assets/morimori-photo-maker/packs/hime_hair_chain_heart.png", width: 36, x: 62, y: 27, z: 61, packId: "himeMoriPack" },
  { id: "hime_brows_princess_arch", name: "姫アーチ眉", category: "まゆげ", src: "assets/morimori-photo-maker/packs/hime_brows_princess_arch.png", width: 33, x: 50, y: 37, z: 45, packId: "himeMoriPack" },
  { id: "hime_brows_doll_soft", name: "姫ドール眉", category: "まゆげ", src: "assets/morimori-photo-maker/packs/hime_brows_doll_soft.png", width: 33, x: 50, y: 37, z: 45, packId: "himeMoriPack" },
  { id: "hime_shadow_pink_pearl", name: "ピンクパール姫シャドウ", category: "アイシャドウ", src: "assets/morimori-photo-maker/packs/hime_shadow_pink_pearl.png", width: 42, x: 50, y: 43, z: 46, packId: "himeMoriPack" },
  { id: "hime_shadow_lavender_royal", name: "ラベンダー姫シャドウ", category: "アイシャドウ", src: "assets/morimori-photo-maker/packs/hime_shadow_lavender_royal.png", width: 42, x: 50, y: 43, z: 46, packId: "himeMoriPack" },
  { id: "hime_shadow_champagne_gold", name: "シャンパン姫シャドウ", category: "アイシャドウ", src: "assets/morimori-photo-maker/packs/hime_shadow_champagne_gold.png", width: 42, x: 50, y: 43, z: 46, packId: "himeMoriPack" },
  { id: "hime_blush_heart_pearl", name: "姫ハートチーク", category: "チーク", src: "assets/morimori-photo-maker/packs/hime_blush_heart_pearl.png", width: 42, x: 50, y: 55, z: 44, packId: "himeMoriPack" },
  { id: "hime_blush_rose_round", name: "姫ローズチーク", category: "チーク", src: "assets/morimori-photo-maker/packs/hime_blush_rose_round.png", width: 42, x: 50, y: 55, z: 44, packId: "himeMoriPack" },
  { id: "hime_lip_princess_pink", name: "姫ピンクリップ", category: "口紅", src: "assets/morimori-photo-maker/packs/hime_lip_princess_pink.png", width: 24, x: 50, y: 59, z: 47, packId: "himeMoriPack" },
  { id: "hime_lip_rose_red", name: "姫ローズリップ", category: "口紅", src: "assets/morimori-photo-maker/packs/hime_lip_rose_red.png", width: 24, x: 50, y: 59, z: 47, packId: "himeMoriPack" },
  { id: "hime_glasses_heart_jewel", name: "姫ハートメガネ", category: "メガネ", src: "assets/morimori-photo-maker/packs/hime_glasses_heart_jewel.png", width: 43, x: 50, y: 43, z: 58, packId: "himeMoriPack" },
  { id: "hime_frame_lace_pearl", name: "姫レースフレーム", category: "フレーム", src: "assets/morimori-photo-maker/packs/hime_frame_lace_pearl.png", width: 100, x: 50, y: 50, z: 12, packId: "himeMoriPack" },
  { id: "hime_frame_royal_gold", name: "王宮ゴールドフレーム", category: "フレーム", src: "assets/morimori-photo-maker/packs/hime_frame_royal_gold.png", width: 100, x: 50, y: 50, z: 12, packId: "himeMoriPack" },
  { id: "hime_frame_castle_window", name: "お城窓フレーム", category: "フレーム", src: "assets/morimori-photo-maker/packs/hime_frame_castle_window.png", width: 100, x: 50, y: 50, z: 12, packId: "himeMoriPack" },
  { id: "hime_frame_lavender_moon", name: "月夜の姫フレーム", category: "フレーム", src: "assets/morimori-photo-maker/packs/hime_frame_lavender_moon.png", width: 100, x: 50, y: 50, z: 12, packId: "himeMoriPack" },
  { id: "hime_part_sparkle_veil", name: "姫きらめきヴェール", category: "アイテム", src: "assets/morimori-photo-maker/packs/hime_part_sparkle_veil.png", width: 95, x: 50, y: 50, z: 62, packId: "himeMoriPack" },
  { id: "hime_part_magic_wand", name: "姫ステッキ", category: "アイテム", src: "assets/morimori-photo-maker/packs/hime_part_magic_wand.png", width: 30, x: 72, y: 35, z: 62, packId: "himeMoriPack" },
  { id: "hime_part_perfume_bottle", name: "姫香水ボトル", category: "アイテム", src: "assets/morimori-photo-maker/packs/hime_part_perfume_bottle.png", width: 28, x: 28, y: 72, z: 62, packId: "himeMoriPack" },
  { id: "hime_part_heart_charm", name: "姫ハートチャーム", category: "アイテム", src: "assets/morimori-photo-maker/packs/hime_part_heart_charm.png", width: 30, x: 72, y: 72, z: 62, packId: "himeMoriPack" },
  { id: "hime_part_rose_petals", name: "姫ローズ花びら", category: "アイテム", src: "assets/morimori-photo-maker/packs/hime_part_rose_petals.png", width: 90, x: 50, y: 50, z: 62, packId: "himeMoriPack" },
  { id: "hime_part_pearl_choker", name: "姫パールチョーカー", category: "アイテム", src: "assets/morimori-photo-maker/packs/hime_part_pearl_choker.png", width: 38, x: 50, y: 68, z: 62, packId: "himeMoriPack" },

  { id: "hairarrange_hair_ribbon_pearl_twins", name: "リボンパールツイン", category: "髪型", src: "assets/morimori-photo-maker/packs/hairarrange_hair_ribbon_pearl_twins.png", width: 68, x: 50, y: 25, z: 30, packId: "hairArrangeGotsumoriPack" },
  { id: "hairarrange_hair_red_black_bow_twins", name: "赤黒リボンツイン", category: "髪型", src: "assets/morimori-photo-maker/packs/hairarrange_hair_red_black_bow_twins.png", width: 68, x: 50, y: 25, z: 30, packId: "hairArrangeGotsumoriPack" },
  { id: "hairarrange_hair_gold_black_rose_twins", name: "金黒ローズツイン", category: "髪型", src: "assets/morimori-photo-maker/packs/hairarrange_hair_gold_black_rose_twins.png", width: 68, x: 50, y: 25, z: 30, packId: "hairArrangeGotsumoriPack" },
  { id: "hairarrange_hair_blue_blonde_twins", name: "青ブロンドツイン", category: "髪型", src: "assets/morimori-photo-maker/packs/hairarrange_hair_blue_blonde_twins.png", width: 68, x: 50, y: 25, z: 30, packId: "hairArrangeGotsumoriPack" },
  { id: "hairarrange_hair_rose_bow_twins", name: "ローズリボンツイン", category: "髪型", src: "assets/morimori-photo-maker/packs/hairarrange_hair_rose_bow_twins.png", width: 68, x: 50, y: 25, z: 30, packId: "hairArrangeGotsumoriPack" },
  { id: "hairarrange_hair_black_bow_sidepony", name: "黒リボンサイドポニー", category: "髪型", src: "assets/morimori-photo-maker/packs/hairarrange_hair_black_bow_sidepony.png", width: 66, x: 50, y: 25, z: 30, packId: "hairArrangeGotsumoriPack" },
  { id: "hairarrange_hair_lace_veil_twins", name: "レースヴェールツイン", category: "髪型", src: "assets/morimori-photo-maker/packs/hairarrange_hair_lace_veil_twins.png", width: 68, x: 50, y: 25, z: 30, packId: "hairArrangeGotsumoriPack" },
  { id: "hairarrange_hair_rainbow_pearl_twins", name: "虹リボンパールツイン", category: "髪型", src: "assets/morimori-photo-maker/packs/hairarrange_hair_rainbow_pearl_twins.png", width: 68, x: 50, y: 25, z: 30, packId: "hairArrangeGotsumoriPack" },
  { id: "hairarrange_hair_heart_balloon_buns", name: "ハートバルーンお団子", category: "髪型", src: "assets/morimori-photo-maker/packs/hairarrange_hair_heart_balloon_buns.png", width: 68, x: 50, y: 25, z: 30, packId: "hairArrangeGotsumoriPack" },
  { id: "hairarrange_hair_silver_twin_drills", name: "シルバードリルツイン", category: "髪型", src: "assets/morimori-photo-maker/packs/hairarrange_hair_silver_twin_drills.png", width: 68, x: 50, y: 25, z: 30, packId: "hairArrangeGotsumoriPack" },
  { id: "hairarrange_hair_side_pony_pearl", name: "片側パール盛り", category: "髪型", src: "assets/morimori-photo-maker/packs/hairarrange_hair_side_pony_pearl.png", width: 66, x: 50, y: 25, z: 30, packId: "hairArrangeGotsumoriPack" },
  { id: "hairarrange_hair_lace_side_updo", name: "レース片寄せアップ", category: "髪型", src: "assets/morimori-photo-maker/packs/hairarrange_hair_lace_side_updo.png", width: 66, x: 50, y: 25, z: 30, packId: "hairArrangeGotsumoriPack" },
  { id: "hairarrange_accessory_glitter_pink_bow", name: "ごつピンクリボン", category: "髪飾り", src: "assets/morimori-photo-maker/packs/hairarrange_accessory_glitter_pink_bow.png", width: 40, x: 50, y: 20, z: 61, packId: "hairArrangeGotsumoriPack" },
  { id: "hairarrange_accessory_pearl_ribbon_chain", name: "リボンパールチェーン", category: "髪飾り", src: "assets/morimori-photo-maker/packs/hairarrange_accessory_pearl_ribbon_chain.png", width: 52, x: 50, y: 28, z: 61, packId: "hairArrangeGotsumoriPack" },
  { id: "hairarrange_accessory_red_black_bows", name: "赤黒リボン連なり", category: "髪飾り", src: "assets/morimori-photo-maker/packs/hairarrange_accessory_red_black_bows.png", width: 34, x: 62, y: 42, z: 61, packId: "hairArrangeGotsumoriPack" },
  { id: "hairarrange_accessory_rose_crown", name: "ごつローズ冠", category: "髪飾り", src: "assets/morimori-photo-maker/packs/hairarrange_accessory_rose_crown.png", width: 46, x: 50, y: 18, z: 61, packId: "hairArrangeGotsumoriPack" },
  { id: "hairarrange_accessory_lace_plush_veil", name: "レースぬいチャーム", category: "髪飾り", src: "assets/morimori-photo-maker/packs/hairarrange_accessory_lace_plush_veil.png", width: 42, x: 38, y: 24, z: 61, packId: "hairArrangeGotsumoriPack" },
  { id: "hairarrange2_hair_01", name: "編み込みクラウン", category: "髪型", src: "assets/morimori-photo-maker/packs/hairarrange2_hair_01.png", width: 66, x: 50, y: 25, z: 30, packId: "hairArrangeGotsumoriPack2" },
  { id: "hairarrange2_hair_02", name: "スター盛りポニー", category: "髪型", src: "assets/morimori-photo-maker/packs/hairarrange2_hair_02.png", width: 66, x: 50, y: 25, z: 30, packId: "hairArrangeGotsumoriPack2" },
  { id: "hairarrange2_hair_03", name: "レースサイドお団子", category: "髪型", src: "assets/morimori-photo-maker/packs/hairarrange2_hair_03.png", width: 66, x: 50, y: 25, z: 30, packId: "hairArrangeGotsumoriPack2" },
  { id: "hairarrange2_hair_04", name: "ふわリボンボブ", category: "髪型", src: "assets/morimori-photo-maker/packs/hairarrange2_hair_04.png", width: 62, x: 50, y: 25, z: 30, packId: "hairArrangeGotsumoriPack2" },
  { id: "hairarrange2_hair_05", name: "宝石サイド三つ編み", category: "髪型", src: "assets/morimori-photo-maker/packs/hairarrange2_hair_05.png", width: 66, x: 50, y: 25, z: 30, packId: "hairArrangeGotsumoriPack2" },
  { id: "hairarrange2_hair_06", name: "黒リボンヴェール", category: "髪型", src: "assets/morimori-photo-maker/packs/hairarrange2_hair_06.png", width: 66, x: 50, y: 25, z: 30, packId: "hairArrangeGotsumoriPack2" },
  { id: "hairarrange2_hair_07", name: "ゴールドトップアップ", category: "髪型", src: "assets/morimori-photo-maker/packs/hairarrange2_hair_07.png", width: 66, x: 50, y: 25, z: 30, packId: "hairArrangeGotsumoriPack2" },
  { id: "hairarrange2_hair_08", name: "ピンクストレート盛り", category: "髪型", src: "assets/morimori-photo-maker/packs/hairarrange2_hair_08.png", width: 66, x: 50, y: 25, z: 30, packId: "hairArrangeGotsumoriPack2" },
  { id: "hairarrange2_hair_09", name: "フェザーウルフ", category: "髪型", src: "assets/morimori-photo-maker/packs/hairarrange2_hair_09.png", width: 66, x: 50, y: 25, z: 30, packId: "hairArrangeGotsumoriPack2" },
  { id: "hairarrange2_hair_10", name: "ローズ低めお団子", category: "髪型", src: "assets/morimori-photo-maker/packs/hairarrange2_hair_10.png", width: 66, x: 50, y: 25, z: 30, packId: "hairArrangeGotsumoriPack2" },
  { id: "hairarrange2_hair_11", name: "ロック盛りポニー", category: "髪型", src: "assets/morimori-photo-maker/packs/hairarrange2_hair_11.png", width: 66, x: 50, y: 25, z: 30, packId: "hairArrangeGotsumoriPack2" },
  { id: "hairarrange2_hair_12", name: "クリスタル編みハーフ", category: "髪型", src: "assets/morimori-photo-maker/packs/hairarrange2_hair_12.png", width: 66, x: 50, y: 25, z: 30, packId: "hairArrangeGotsumoriPack2" },
  { id: "hairarrange2_accessory_01", name: "星パールヘッドチェーン", category: "髪飾り", src: "assets/morimori-photo-maker/packs/hairarrange2_accessory_01.png", width: 48, x: 50, y: 22, z: 61, packId: "hairArrangeGotsumoriPack2" },
  { id: "hairarrange2_accessory_02", name: "黒レースローズリボン", category: "髪飾り", src: "assets/morimori-photo-maker/packs/hairarrange2_accessory_02.png", width: 42, x: 50, y: 22, z: 61, packId: "hairArrangeGotsumoriPack2" },
  { id: "hairarrange2_accessory_03", name: "ゼリーバタフライピン", category: "髪飾り", src: "assets/morimori-photo-maker/packs/hairarrange2_accessory_03.png", width: 44, x: 50, y: 24, z: 61, packId: "hairArrangeGotsumoriPack2" },
  { id: "hairarrange2_accessory_04", name: "ゴールド王冠コーム", category: "髪飾り", src: "assets/morimori-photo-maker/packs/hairarrange2_accessory_04.png", width: 44, x: 50, y: 20, z: 61, packId: "hairArrangeGotsumoriPack2" },
  { id: "hairarrange2_accessory_05", name: "カラフルリボンガーランド", category: "髪飾り", src: "assets/morimori-photo-maker/packs/hairarrange2_accessory_05.png", width: 50, x: 50, y: 26, z: 61, packId: "hairArrangeGotsumoriPack2" },

  { id: "vivid_reptile_plush_chameleon", name: "ビビッドカメレオン", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/vivid_reptile_plush_chameleon.png", width: 34, x: 32, y: 72, z: 62, packId: "vividReptilePack" },
  { id: "vivid_reptile_plush_gecko", name: "ターコイズヤモリ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/vivid_reptile_plush_gecko.png", width: 34, x: 70, y: 72, z: 62, packId: "vividReptilePack" },
  { id: "vivid_reptile_plush_bearded_dragon", name: "ピンクフトアゴ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/vivid_reptile_plush_bearded_dragon.png", width: 34, x: 32, y: 74, z: 62, packId: "vividReptilePack" },
  { id: "vivid_reptile_plush_snake", name: "むらさきヘビ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/vivid_reptile_plush_snake.png", width: 34, x: 70, y: 74, z: 62, packId: "vividReptilePack" },
  { id: "vivid_reptile_plush_turtle", name: "レインボーかめ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/vivid_reptile_plush_turtle.png", width: 34, x: 30, y: 74, z: 62, packId: "vividReptilePack" },
  { id: "vivid_reptile_plush_iguana", name: "コーラルイグアナ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/vivid_reptile_plush_iguana.png", width: 34, x: 72, y: 72, z: 62, packId: "vividReptilePack" },
  { id: "vivid_reptile_plush_rainbow_skink", name: "虹色スキンク", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/vivid_reptile_plush_rainbow_skink.png", width: 34, x: 32, y: 70, z: 62, packId: "vividReptilePack" },
  { id: "vivid_reptile_plush_crocodile", name: "むらさきワニ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/vivid_reptile_plush_crocodile.png", width: 34, x: 70, y: 70, z: 62, packId: "vividReptilePack" },
  { id: "vivid_reptile_plush_crested_gecko", name: "オレンジクレス", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/vivid_reptile_plush_crested_gecko.png", width: 34, x: 30, y: 72, z: 62, packId: "vividReptilePack" },
  { id: "vivid_reptile_plush_leopard_gecko", name: "レモンレオパ", category: "ぬいぐるみ", src: "assets/morimori-photo-maker/packs/vivid_reptile_plush_leopard_gecko.png", width: 34, x: 72, y: 74, z: 62, packId: "vividReptilePack" },

  { id: "variety_glowing_eyes_blue", name: "光る目", category: "アイシャドウ", src: "assets/morimori-photo-maker/packs/variety_glowing_eyes_blue.png", width: 48, x: 50, y: 43, z: 46, packId: "varietyPack" },
  { id: "variety_glowing_eyes_pink", name: "光る目2", category: "アイシャドウ", src: "assets/morimori-photo-maker/packs/variety_glowing_eyes_pink.png", width: 48, x: 50, y: 43, z: 46, packId: "varietyPack" },
  { id: "variety_glowing_eyes_vampire", name: "光る目3", category: "アイシャドウ", src: "assets/morimori-photo-maker/packs/variety_glowing_eyes_vampire.png", width: 48, x: 50, y: 43, z: 46, packId: "varietyPack" },
  { id: "variety_pop_glasses", name: "飛び出るメガネ", category: "メガネ", src: "assets/morimori-photo-maker/packs/variety_pop_glasses.png", width: 50, x: 50, y: 43, z: 58, packId: "varietyPack" },
  { id: "variety_rainbow_brows", name: "レインボーまゆげ", category: "まゆげ", src: "assets/morimori-photo-maker/packs/variety_rainbow_brows.png", width: 36, x: 50, y: 37, z: 45, packId: "varietyPack" },
  { id: "variety_open_mouth", name: "開く口", category: "口紅", src: "assets/morimori-photo-maker/packs/variety_open_mouth.png", width: 26, x: 50, y: 59, z: 47, packId: "varietyPack" },
  { id: "variety_drool", name: "動くよだれ", category: "感情", src: "assets/morimori-photo-maker/packs/variety_drool.gif", width: 22, x: 50, y: 55, z: 63, packId: "varietyPack" },
  { id: "variety_vampire_fangs", name: "吸血鬼", category: "口紅", src: "assets/morimori-photo-maker/packs/variety_vampire_fangs.png", width: 26, x: 50, y: 59, z: 47, packId: "varietyPack" },
  { id: "variety_milk_bottle_glasses", name: "牛乳瓶メガネ", category: "メガネ", src: "assets/morimori-photo-maker/packs/variety_milk_bottle_glasses.png", width: 46, x: 50, y: 43, z: 58, packId: "varietyPack" },
  { id: "variety_nose_bandage", name: "鼻ばんそうこう", category: "アイテム", src: "assets/morimori-photo-maker/packs/variety_nose_bandage.png", width: 20, x: 50, y: 50, z: 62, packId: "varietyPack" },
  { id: "variety_manga_meat", name: "漫画みたいな肉", category: "アイテム", src: "assets/morimori-photo-maker/packs/variety_manga_meat.png", width: 34, x: 28, y: 72, z: 62, packId: "varietyPack" },
  { id: "variety_big_rice", name: "デカ盛りごはん", category: "アイテム", src: "assets/morimori-photo-maker/packs/variety_big_rice.png", width: 36, x: 72, y: 72, z: 62, packId: "varietyPack" },
];

const CATEGORIES = ["髪型", "髪飾り", "まゆげ", "アイシャドウ", "つけまつげ", "ネイル", "チーク", "口紅", "メガネ", "イヤリング", "鼻ピアス", "感情", "フレーム", "アニメ背景", "アイテム", "ぬいぐるみ"];

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
  seriousPack: {
    id: "seriousPack",
    name: "真面目盛りパック",
    productId: "com.tokyonasu.morimoriphotomaker.serious",
    unlocked: false,
  },
  yankeeDecoPack: {
    id: "yankeeDecoPack",
    name: "ヤンキーデコパック",
    productId: "com.tokyonasu.morimoriphotomaker.yankee.deco",
    unlocked: false,
  },
  bubbleDecoPack: {
    id: "bubbleDecoPack",
    name: "昭和バブルデコパック",
    productId: "com.tokyonasu.morimoriphotomaker.bubble.deco",
    unlocked: false,
  },
  kyunNekoPack: {
    id: "kyunNekoPack",
    name: "きゅんねこパック",
    productId: "com.tokyonasu.morimoriphotomaker.kyun.neko",
    unlocked: false,
  },
  mofuUsaPack: {
    id: "mofuUsaPack",
    name: "もふもふうさちゃんパック",
    productId: "com.tokyonasu.morimoriphotomaker.mofu.usa",
    unlocked: false,
  },
  koreanHairPack: {
    id: "koreanHairPack",
    name: "韓国ヘアパック",
    productId: "com.tokyonasu.morimoriphotomaker.korean.hair",
    unlocked: false,
  },
  koreanFashionPack: {
    id: "koreanFashionPack",
    name: "韓国ファッションパック",
    productId: "com.tokyonasu.morimoriphotomaker.korean.fashion",
    unlocked: false,
  },
  himeMoriPack: {
    id: "himeMoriPack",
    name: "姫盛りパック",
    productId: "com.tokyonasu.morimoriphotomaker.hime.mori",
    unlocked: false,
  },
  hairArrangeGotsumoriPack: {
    id: "hairArrangeGotsumoriPack",
    name: "ヘアアレごつ盛りパック",
    productId: "com.tokyonasu.morimoriphotomaker.hairarrange.gotsumori",
    unlocked: false,
  },
  hairArrangeGotsumoriPack2: {
    id: "hairArrangeGotsumoriPack2",
    name: "ヘアアレごつ盛りパック2",
    productId: "com.tokyonasu.morimoriphotomaker.hairarrange.gotsumori2",
    unlocked: false,
  },
  vividReptilePack: {
    id: "vividReptilePack",
    name: "ビビッド爬虫類パック",
    productId: "com.tokyonasu.morimoriphotomaker.vivid.reptile",
    unlocked: false,
  },
  varietyPack: {
    id: "varietyPack",
    name: "バラエティーパック",
    productId: "com.tokyonasu.morimoriphotomaker.variety",
    unlocked: false,
  },
  cabaretNailPack: {
    id: "cabaretNailPack",
    name: "キャバ嬢ネイルパック",
    productId: "com.tokyonasu.morimoriphotomaker.cabaret.nail",
    unlocked: false,
  },
  emotionPack: {
    id: "emotionPack",
    name: "感情パック",
    productId: "com.tokyonasu.morimoriphotomaker.emotion",
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
const scaleValue = document.querySelector("#scaleValue");
const rotateValue = document.querySelector("#rotateValue");
const opacityValue = document.querySelector("#opacityValue");
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

const SPLIT_PAIR_CATEGORIES = ["\u307e\u3086\u3052", "\u30a2\u30a4\u30b7\u30e3\u30c9\u30a6", "\u3064\u3051\u307e\u3064\u3052", "\u30c1\u30fc\u30af", "\u30a4\u30e4\u30ea\u30f3\u30b0"];
const imageCache = new Map();
let thumbObserver = null;

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
  thumbObserver?.disconnect();
  assetGrid.innerHTML = "";
  thumbObserver = createThumbObserver();
  ASSETS.filter((asset) => asset.category === currentCategory).forEach((asset) => {
    const pack = getPack(asset);
    const locked = !isAssetUnlocked(asset);
    const card = document.createElement("button");
    card.type = "button";
    card.className = `asset-card${locked ? " locked" : ""}`;
    card.disabled = locked;
    card.title = locked ? `${pack.name}で解放` : asset.name;

    const thumb = document.createElement("span");
    thumb.className = "asset-thumb";
    const img = document.createElement("img");
    img.alt = "";
    img.decoding = "async";
    img.loading = "lazy";
    img.dataset.src = asset.src;
    thumb.appendChild(img);

    if (locked) {
      const badge = document.createElement("b");
      badge.className = "lock-badge";
      badge.textContent = "LOCK";
      thumb.appendChild(badge);
    }

    const name = document.createElement("span");
    name.textContent = asset.name;
    card.append(thumb, name);

    if (pack.id !== "free") {
      const badge = document.createElement("small");
      badge.className = "pack-badge";
      badge.textContent = pack.name;
      card.appendChild(badge);
    }

    card.addEventListener("click", () => {
      if (locked) return;
      addLayer(asset);
    });
    assetGrid.appendChild(card);
    thumbObserver.observe(img);
  });
}

function createThumbObserver() {
  if (!("IntersectionObserver" in window)) {
    return {
      observe(img) {
        img.src = img.dataset.src;
        img.removeAttribute("data-src");
      },
      disconnect() {},
    };
  }
  return new IntersectionObserver((entries, observer) => {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return;
      const img = entry.target;
      img.src = img.dataset.src;
      img.removeAttribute("data-src");
      observer.unobserve(img);
    });
  }, {
    root: null,
    rootMargin: "180px 0px",
  });
}

function addLayer(asset, overrides = {}) {
  if (!isAssetUnlocked(asset)) {
    return;
  }
  if (shouldSplitPair(asset) && !overrides.keepSingleLayer) {
    addPairLayers(asset, overrides);
    return;
  }
  const layer = createLayer(asset, overrides);
  layers.push(layer);
  selectedId = layer.id;
  renderLayers();
}

function shouldSplitPair(asset) {
  return SPLIT_PAIR_CATEGORIES.includes(asset.category) && !asset.background;
}

function createLayer(asset, overrides = {}) {
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
  return layer;
}

function addPairLayers(asset, overrides = {}) {
  const baseWidth = Number(overrides.width ?? asset.width);
  const baseX = Number(overrides.x ?? asset.x);
  const pairZ = nextZ(asset.z);
  const common = {
    ...overrides,
    width: baseWidth / 2,
  };
  const left = createLayer(asset, {
    ...common,
    id: uid(),
    name: `${asset.name} ?`,
    x: baseX - baseWidth * 0.25,
    z: pairZ,
    cropSide: "left",
    cropAspect: 2,
    keepSingleLayer: true,
  });
  const right = createLayer(asset, {
    ...common,
    id: uid(),
    name: `${asset.name} ?`,
    x: baseX + baseWidth * 0.25,
    z: pairZ + 1,
    cropSide: "right",
    cropAspect: 2,
    keepSingleLayer: true,
  });
  layers.push(left, right);
  selectedId = right.id;
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
    el.className = `layer${layer.id === selectedId ? " selected" : ""}${layer.background ? " background" : ""}${layer.cropSide ? " pair-part" : ""}`;
    el.dataset.id = layer.id;
    const img = document.createElement("img");
    img.src = layer.src;
    img.alt = "";
    img.decoding = "async";
    if (layer.cropSide) {
      img.className = layer.cropSide === "right" ? "crop-right" : "crop-left";
    }
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
  el.style.aspectRatio = layer.cropAspect ? `1 / ${layer.cropAspect}` : "";
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
  updateSliderValues();
  if (selected.background) {
    opacityRange.disabled = false;
    deleteButton.disabled = false;
    duplicateButton.disabled = false;
  }
}

function updateSliderValues() {
  scaleValue.textContent = `${Math.round(Number(scaleRange.value))}%`;
  rotateValue.textContent = `${Math.round(Number(rotateRange.value))}°`;
  opacityValue.textContent = `${Math.round(Number(opacityRange.value))}%`;
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
  if (imageCache.has(src)) {
    return imageCache.get(src);
  }
  const promise = new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = (error) => {
      imageCache.delete(src);
      reject(error);
    };
    img.src = src;
  });
  imageCache.set(src, promise);
  return promise;
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
    ctx.translate(x, y);
    ctx.rotate((layer.rotation * Math.PI) / 180);
    ctx.scale(layer.flip, 1);
    if (layer.cropSide) {
      const sw = img.naturalWidth / 2;
      const sh = img.naturalHeight;
      const sx = layer.cropSide === "right" ? sw : 0;
      const h = (sh / sw) * w;
      ctx.drawImage(img, sx, 0, sw, sh, -w / 2, -h / 2, w, h);
    } else {
      const h = (img.naturalHeight / img.naturalWidth) * w;
      ctx.drawImage(img, -w / 2, -h / 2, w, h);
    }
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

scaleRange.addEventListener("input", () => {
  updateSliderValues();
  changeSelected((layer) => (layer.width = Number(scaleRange.value)));
});
rotateRange.addEventListener("input", () => {
  updateSliderValues();
  changeSelected((layer) => (layer.rotation = Number(rotateRange.value)));
});
opacityRange.addEventListener("input", () => {
  updateSliderValues();
  changeSelected((layer) => (layer.opacity = Number(opacityRange.value) / 100));
});
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
updateSliderValues();
