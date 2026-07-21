using System;

namespace ShinobiZero.Core
{
    public struct PlatformStat
    {
        public readonly string Id;
        public readonly int Value;

        public PlatformStat(string id, int value)
        {
            if (string.IsNullOrWhiteSpace(id)) throw new ArgumentException("A stat ID is required.", "id");
            Id = id;
            Value = value;
        }
    }

    public sealed class PlatformProgressSnapshot
    {
        public const string Matches = "SZ_STAT_MATCHES";
        public const string Wins = "SZ_STAT_WINS";
        public const string Losses = "SZ_STAT_LOSSES";
        public const string LegsWon = "SZ_STAT_LEGS_WON";
        public const string PlayerThrows = "SZ_STAT_PLAYER_THROWS";
        public const string Bulls = "SZ_STAT_BULLS";
        public const string Triples = "SZ_STAT_TRIPLES";
        public const string BestTurn = "SZ_STAT_BEST_TURN";
        public const string BestCheckout = "SZ_STAT_BEST_CHECKOUT";

        private readonly PlatformStat[] _stats;
        private readonly string[] _achievements;

        public PlatformStat[] Stats { get { return _stats; } }
        public string[] Achievements { get { return _achievements; } }

        private PlatformProgressSnapshot(PlatformStat[] stats, string[] achievements)
        {
            _stats = stats;
            _achievements = achievements;
        }

        public static PlatformProgressSnapshot From(CareerStats career)
        {
            if (career == null) throw new ArgumentNullException("career");
            return new PlatformProgressSnapshot(new[]
            {
                new PlatformStat(Matches, career.Matches),
                new PlatformStat(Wins, career.Wins),
                new PlatformStat(Losses, career.Losses),
                new PlatformStat(LegsWon, career.LegsWon),
                new PlatformStat(PlayerThrows, career.PlayerThrows),
                new PlatformStat(Bulls, career.Bulls),
                new PlatformStat(Triples, career.Triples),
                new PlatformStat(BestTurn, career.BestTurn),
                new PlatformStat(BestCheckout, career.BestCheckout)
            }, AchievementCatalog.Evaluate(career));
        }
    }
}
