namespace ShinobiZero.Core
{
    public enum GameLanguage { Japanese, English }

    public static class LocalizationCatalog
    {
        public static string Literal(string japanese, GameLanguage language)
        {
            if (language == GameLanguage.Japanese || string.IsNullOrEmpty(japanese)) return japanese;
            switch (japanese)
            {
                case "手裏剣ダーツ　対戦相手を選択": return "SHURIKEN DARTS  SELECT YOUR RIVAL";
                case "開始点": return "START SCORE";
                case "投げ方を調整": return "CALIBRATE THROW";
                case "投げ方を再調整": return "RECALIBRATE";
                case "遊び方": return "HOW TO PLAY";
                case "設定": return "SETTINGS";
                case "終了": return "QUIT";
                case "対戦を始める": return "BEGIN DUEL";
                case "下から上へ払って投げる": return "SWIPE UP TO THROW";
                case "再戦する": return "REMATCH";
                case "相手を選び直す": return "CHANGE RIVAL";
                case "勝利": return "VICTORY";
                case "敗北": return "DEFEAT";
                case "画面の下から上へ\n普段の強さで払ってください": return "SWIPE FROM LOW TO HIGH\nWITH YOUR NATURAL THROW";
                case "自然な速さで上へ3回払う": return "MAKE 3 NATURAL UPWARD THROWS";
                case "戻る": return "BACK";
                case "次へ": return "NEXT";
                case "始める": return "BEGIN";
                case "スキップ": return "SKIP";
                case "効果音": return "SOUND";
                case "音量": return "VOLUME";
                case "触覚フィードバック": return "HAPTICS";
                case "カメラ反応を抑える": return "REDUCED MOTION";
                case "英語UI": return "ENGLISH UI";
                case "フルスクリーン": return "FULLSCREEN";
                case "決定": return "DONE";
                case "静止": return "PAUSED";
                case "試合は止まっています": return "THE DUEL IS PAUSED";
                case "試合へ戻る": return "RESUME";
                case "対戦相手選択へ": return "LEAVE DUEL";
                default: return japanese;
            }
        }
    }
}
