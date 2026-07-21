using System;

namespace ShinobiZero.Core
{
    public struct MatchEnduranceReport
    {
        public readonly int Matches;
        public readonly int Throws;
        public readonly int Busts;
        public readonly int Legs;
        public readonly int MaximumThrowsInMatch;

        public MatchEnduranceReport(int matches, int throws, int busts, int legs, int maximumThrowsInMatch)
        {
            Matches = matches;
            Throws = throws;
            Busts = busts;
            Legs = legs;
            MaximumThrowsInMatch = maximumThrowsInMatch;
        }
    }

    public static class MatchEnduranceSimulator
    {
        public static MatchEnduranceReport Run(int matchCount, uint seed)
        {
            if (matchCount <= 0) throw new ArgumentOutOfRangeException("matchCount");
            var state = seed == 0 ? 1u : seed;
            var totalThrows = 0;
            var totalBusts = 0;
            var totalLegs = 0;
            var maximumThrows = 0;

            for (var matchIndex = 0; matchIndex < matchCount; matchIndex++)
            {
                var score = matchIndex % 2 == 0 ? 301 : 501;
                var doubleOut = (matchIndex / 2) % 2 == 0;
                var legsToWin = (matchIndex / 4) % 2 == 0 ? 1 : 2;
                var starter = (matchIndex / 8) % 2 == 0 ? Combatant.Player : Combatant.Enemy;
                var skill = OpponentTuningCatalog.Get(matchIndex % OpponentTuningCatalog.Count).Skill;
                var match = new MatchEngine();
                match.Start(new MatchConfig(score, doubleOut, legsToWin, starter));
                var throwsInMatch = 0;

                while (!match.IsFinished)
                {
                    if (throwsInMatch >= 600) throw new InvalidOperationException("Endurance match did not terminate.");
                    var hit = SelectHit(match, skill, throwsInMatch, ref state);
                    var outcome = match.Submit(hit);
                    throwsInMatch++;
                    totalThrows++;
                    if (outcome.Score.Bust) totalBusts++;
                    if (outcome.LegEnded) totalLegs++;
                    VerifyInvariants(match);
                }
                if (!match.Winner.HasValue) throw new InvalidOperationException("Completed endurance match has no winner.");
                if (throwsInMatch > maximumThrows) maximumThrows = throwsInMatch;
            }
            return new MatchEnduranceReport(matchCount, totalThrows, totalBusts, totalLegs, maximumThrows);
        }

        private static DartHit SelectHit(MatchEngine match, float skill, int throwsInMatch, ref uint state)
        {
            var remaining = match.Turn == Combatant.Player ? match.PlayerScore : match.EnemyScore;
            var route = CheckoutAdvisor.Find(remaining, match.DartsLeft, match.Config.DoubleOut);
            var intended = route.IsPossible ? route.Hits[0] : SetupHit(remaining, match.DartsLeft, match.Config.DoubleOut);
            state = unchecked(state * 1664525u + 1013904223u);
            if (throwsInMatch > 420) return intended;
            var errorThreshold = (int)((1f - skill) * 180f);
            var roll = (int)((state >> 8) % 1000u);
            if (roll < errorThreshold / 3) return DartHit.Miss;
            if (roll < errorThreshold) return new DartHit(1 + (int)(state % 20u), 1);
            return intended;
        }

        private static DartHit SetupHit(int remaining, int dartsLeft, bool doubleOut)
        {
            if (remaining > 170) return new DartHit(20, 3);
            if (dartsLeft < 3) return DartHit.Miss;
            if (!doubleOut) return remaining <= 60 ? new DartHit(20, Math.Max(1, Math.Min(3, remaining / 20))) : new DartHit(20, 3);
            if ((remaining & 1) != 0 && remaining > 3) return new DartHit(1, 1);
            if (remaining > 4) return new DartHit(2, 1);
            return DartHit.Miss;
        }

        private static void VerifyInvariants(MatchEngine match)
        {
            if (match.PlayerScore < 0 || match.EnemyScore < 0) throw new InvalidOperationException("Negative score.");
            if (match.DartsLeft < 1 || match.DartsLeft > 3) throw new InvalidOperationException("Invalid darts remaining.");
            if (match.Round < 1) throw new InvalidOperationException("Invalid round.");
            if (match.PlayerLegs < 0 || match.EnemyLegs < 0) throw new InvalidOperationException("Negative legs.");
            if (!match.IsFinished && (match.PlayerScore < 1 || match.EnemyScore < 1))
                throw new InvalidOperationException("Active match reached zero without ending.");
        }
    }
}
