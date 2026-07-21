using System.Collections.Generic;

namespace ShinobiZero.Core
{
    public static class AchievementCatalog
    {
        public const string FirstVictory = "SZ_FIRST_VICTORY";
        public const string CenturyCheckout = "SZ_CHECKOUT_100";
        public const string MaximumTurn = "SZ_MAXIMUM_180";
        public const string BullDiscipline = "SZ_BULL_25";
        public const string FiveShadows = "SZ_DEFEAT_ALL_FIVE";
        public const string TenVictories = "SZ_TEN_VICTORIES";

        public static string[] Evaluate(CareerStats stats)
        {
            var unlocked = new List<string>();
            if (stats == null) return unlocked.ToArray();
            if (stats.Wins >= 1) unlocked.Add(FirstVictory);
            if (stats.BestCheckout >= 100) unlocked.Add(CenturyCheckout);
            if (stats.BestTurn >= 180) unlocked.Add(MaximumTurn);
            if (stats.Bulls >= 25) unlocked.Add(BullDiscipline);
            if (HasDefeatedAll(stats.OpponentWins, 5)) unlocked.Add(FiveShadows);
            if (stats.Wins >= 10) unlocked.Add(TenVictories);
            return unlocked.ToArray();
        }

        public static string JapaneseTitle(string id)
        {
            if (id == FirstVictory) return "初陣の勝者";
            if (id == CenturyCheckout) return "百の仕留め";
            if (id == MaximumTurn) return "一八〇・極";
            if (id == BullDiscipline) return "心眼";
            if (id == FiveShadows) return "五影制覇";
            if (id == TenVictories) return "十番勝負";
            return id;
        }

        public static string EnglishTitle(string id)
        {
            if (id == FirstVictory) return "First Shadow Defeated";
            if (id == CenturyCheckout) return "Century Finish";
            if (id == MaximumTurn) return "Perfect 180";
            if (id == BullDiscipline) return "Mind's Eye";
            if (id == FiveShadows) return "Master of Five Shadows";
            if (id == TenVictories) return "Ten Duels";
            return id;
        }

        public static string Title(string id, GameLanguage language)
        {
            return language == GameLanguage.English ? EnglishTitle(id) : JapaneseTitle(id);
        }

        public static string TranslateJapaneseTitle(string title, GameLanguage language)
        {
            if (language == GameLanguage.Japanese) return title;
            var ids = new[] { FirstVictory, CenturyCheckout, MaximumTurn, BullDiscipline, FiveShadows, TenVictories };
            for (var i = 0; i < ids.Length; i++)
                if (JapaneseTitle(ids[i]) == title) return EnglishTitle(ids[i]);
            return title;
        }

        private static bool HasDefeatedAll(int[] wins, int required)
        {
            if (wins == null || wins.Length < required) return false;
            for (var i = 0; i < required; i++) if (wins[i] <= 0) return false;
            return true;
        }
    }
}
