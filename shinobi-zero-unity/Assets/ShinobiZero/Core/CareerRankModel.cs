namespace ShinobiZero.Core
{
    public enum CareerRank { Initiate, Genin, Chunin, Jonin, Shadow }

    public struct CareerRankProgress
    {
        public readonly CareerRank Rank;
        public readonly bool IsMaximum;
        public readonly int NextWins;
        public readonly int NextOpponents;

        public CareerRankProgress(CareerRank rank, bool isMaximum, int nextWins, int nextOpponents)
        {
            Rank = rank;
            IsMaximum = isMaximum;
            NextWins = nextWins;
            NextOpponents = nextOpponents;
        }
    }

    public static class CareerRankModel
    {
        public static bool IsPromotion(CareerRank previous, CareerRank current) { return current > previous; }

        public static CareerRankProgress Evaluate(CareerStats stats)
        {
            var wins = stats == null ? 0 : stats.Wins;
            var opponents = CountDefeated(stats == null ? null : stats.OpponentWins);
            if (wins >= 10 && opponents >= 5) return new CareerRankProgress(CareerRank.Shadow, true, 10, 5);
            if (wins >= 7 && opponents >= 4) return new CareerRankProgress(CareerRank.Jonin, false, 10, 5);
            if (wins >= 3 && opponents >= 2) return new CareerRankProgress(CareerRank.Chunin, false, 7, 4);
            if (wins >= 1 && opponents >= 1) return new CareerRankProgress(CareerRank.Genin, false, 3, 2);
            return new CareerRankProgress(CareerRank.Initiate, false, 1, 1);
        }

        public static string Japanese(CareerRank rank)
        {
            if (rank == CareerRank.Genin) return "下忍";
            if (rank == CareerRank.Chunin) return "中忍";
            if (rank == CareerRank.Jonin) return "上忍";
            if (rank == CareerRank.Shadow) return "影";
            return "見習い";
        }

        public static string English(CareerRank rank)
        {
            if (rank == CareerRank.Genin) return "GENIN";
            if (rank == CareerRank.Chunin) return "CHUNIN";
            if (rank == CareerRank.Jonin) return "JONIN";
            if (rank == CareerRank.Shadow) return "SHADOW";
            return "INITIATE";
        }

        private static int CountDefeated(int[] opponentWins)
        {
            if (opponentWins == null) return 0;
            var count = 0;
            for (var i = 0; i < opponentWins.Length; i++) if (opponentWins[i] > 0) count++;
            return count;
        }
    }
}
