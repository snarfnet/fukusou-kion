using System;

namespace ShinobiZero.Core
{
    [Serializable]
    public sealed class CareerStats
    {
        public int Version = 2;
        public long Revision;
        public long UpdatedUtcTicks;
        public int Matches;
        public int Wins;
        public int Losses;
        public int LegsWon;
        public int PlayerThrows;
        public int ScoringThrows;
        public int Bulls;
        public int Triples;
        public int BestTurn;
        public int BestCheckout;
        public int[] OpponentWins = new int[5];

        public float HitRate { get { return PlayerThrows == 0 ? 0f : ScoringThrows / (float)PlayerThrows; } }

        public void EnsureOpponentCount(int count)
        {
            if (count < 0) throw new ArgumentOutOfRangeException("count");
            if (OpponentWins != null && OpponentWins.Length >= count) return;
            var resized = new int[count];
            if (OpponentWins != null) Array.Copy(OpponentWins, resized, OpponentWins.Length);
            OpponentWins = resized;
        }

        public void Normalize(int opponentCount)
        {
            Version = 2;
            Revision = Math.Max(0L, Revision);
            UpdatedUtcTicks = Math.Max(0L, UpdatedUtcTicks);
            Matches = Math.Max(0, Matches);
            Wins = Math.Max(0, Wins);
            Losses = Math.Max(0, Losses);
            var completed = (long)Wins + Losses;
            Matches = (int)Math.Min(int.MaxValue, Math.Max((long)Matches, completed));
            LegsWon = Math.Max(Wins, LegsWon);
            PlayerThrows = Math.Max(0, PlayerThrows);
            ScoringThrows = Math.Max(0, Math.Min(PlayerThrows, ScoringThrows));
            Bulls = Math.Max(0, Math.Min(PlayerThrows, Bulls));
            Triples = Math.Max(0, Math.Min(PlayerThrows, Triples));
            BestTurn = Math.Max(0, Math.Min(180, BestTurn));
            BestCheckout = Math.Max(0, Math.Min(170, BestCheckout));
            EnsureOpponentCount(opponentCount);
            for (var i = 0; i < OpponentWins.Length; i++) OpponentWins[i] = Math.Max(0, OpponentWins[i]);
        }
    }

    public static class CareerSaveResolver
    {
        public static CareerStats Choose(CareerStats local, CareerStats cloud)
        {
            if (local == null) return cloud;
            if (cloud == null) return local;
            if (cloud.Revision != local.Revision) return cloud.Revision > local.Revision ? cloud : local;
            if (cloud.Matches != local.Matches) return cloud.Matches > local.Matches ? cloud : local;
            if (cloud.UpdatedUtcTicks != local.UpdatedUtcTicks) return cloud.UpdatedUtcTicks > local.UpdatedUtcTicks ? cloud : local;
            return local;
        }

        public static bool CanRestoreCheckpoint(CareerStats checkpoint, CareerStats current)
        {
            return checkpoint != null && ReferenceEquals(Choose(checkpoint, current), checkpoint);
        }
    }

    public sealed class CareerTracker
    {
        private readonly CareerStats _stats;
        private int _opponent;
        private int _turnScore;
        private bool _active;

        public CareerTracker(CareerStats stats)
        {
            if (stats == null) throw new ArgumentNullException("stats");
            _stats = stats;
        }

        public void BeginMatch(int opponent, int opponentCount)
        {
            if (opponent < 0 || opponent >= opponentCount) throw new ArgumentOutOfRangeException("opponent");
            _stats.EnsureOpponentCount(opponentCount);
            _opponent = opponent;
            _turnScore = 0;
            _active = true;
        }

        public void RecordPlayerThrow(DartHit hit, bool bust, bool turnEnded, bool legWon, bool matchWon)
        {
            if (!_active) throw new InvalidOperationException("No active match.");
            _stats.PlayerThrows++;
            if (hit.Score > 0) _stats.ScoringThrows++;
            if (hit.Base == 25) _stats.Bulls++;
            if (hit.Multiplier == 3) _stats.Triples++;
            _turnScore = bust ? 0 : _turnScore + hit.Score;

            if (legWon)
            {
                _stats.BestCheckout = Math.Max(_stats.BestCheckout, _turnScore);
                _stats.LegsWon++;
            }
            if (matchWon)
            {
                Complete(true);
                return;
            }
            if (turnEnded)
            {
                _stats.BestTurn = Math.Max(_stats.BestTurn, _turnScore);
                _turnScore = 0;
            }
        }

        public void RecordEnemyWin()
        {
            if (!_active) throw new InvalidOperationException("No active match.");
            Complete(false);
        }

        public void AbortMatch()
        {
            _active = false;
            _turnScore = 0;
        }

        private void Complete(bool won)
        {
            _stats.BestTurn = Math.Max(_stats.BestTurn, _turnScore);
            _stats.Matches++;
            if (won)
            {
                _stats.Wins++;
                _stats.OpponentWins[_opponent]++;
            }
            else _stats.Losses++;
            _active = false;
            _turnScore = 0;
        }
    }
}
