using System;

namespace ShinobiZero.Core
{
    [Serializable]
    public sealed class MatchPerformanceSnapshot
    {
        public int Version = 1;
        public int Throws;
        public int ScoringHits;
        public int CountedScore;
        public int BestTurn;
        public int BestCheckout;
        public int Bulls;
        public int Triples;
        public int CurrentTurnScore;
    }

    public sealed class MatchPerformance
    {
        public int Throws { get; internal set; }
        public int ScoringHits { get; internal set; }
        public int CountedScore { get; internal set; }
        public int BestTurn { get; internal set; }
        public int BestCheckout { get; internal set; }
        public int Bulls { get; internal set; }
        public int Triples { get; internal set; }
        public float ThreeDartAverage { get { return Throws == 0 ? 0f : CountedScore * 3f / Throws; } }
        public float HitRate { get { return Throws == 0 ? 0f : ScoringHits / (float)Throws; } }
    }

    public sealed class MatchPerformanceTracker
    {
        public MatchPerformance Performance { get; private set; }
        private int _turnScore;

        public MatchPerformanceTracker() { Reset(); }

        public void Reset()
        {
            Performance = new MatchPerformance();
            _turnScore = 0;
        }

        public void Record(DartHit hit, bool bust, bool turnEnded, bool legEnded)
        {
            Performance.Throws++;
            if (hit.Score > 0) Performance.ScoringHits++;
            if (hit.Base == 25) Performance.Bulls++;
            if (hit.Multiplier == 3) Performance.Triples++;
            _turnScore = bust ? 0 : _turnScore + hit.Score;
            if (!turnEnded) return;
            Performance.CountedScore += _turnScore;
            Performance.BestTurn = Math.Max(Performance.BestTurn, _turnScore);
            if (legEnded) Performance.BestCheckout = Math.Max(Performance.BestCheckout, _turnScore);
            _turnScore = 0;
        }

        public MatchPerformanceSnapshot Capture()
        {
            return new MatchPerformanceSnapshot
            {
                Throws = Performance.Throws,
                ScoringHits = Performance.ScoringHits,
                CountedScore = Performance.CountedScore,
                BestTurn = Performance.BestTurn,
                BestCheckout = Performance.BestCheckout,
                Bulls = Performance.Bulls,
                Triples = Performance.Triples,
                CurrentTurnScore = _turnScore
            };
        }

        public bool TryRestore(MatchPerformanceSnapshot snapshot)
        {
            if (snapshot == null || snapshot.Version != 1 || snapshot.Throws < 0
                || snapshot.ScoringHits < 0 || snapshot.ScoringHits > snapshot.Throws
                || snapshot.CountedScore < 0 || snapshot.CountedScore > (long)snapshot.Throws * 180
                || snapshot.BestTurn < 0 || snapshot.BestTurn > 180
                || snapshot.BestCheckout < 0 || snapshot.BestCheckout > 170
                || snapshot.Bulls < 0 || snapshot.Bulls > snapshot.Throws
                || snapshot.Triples < 0 || snapshot.Triples > snapshot.Throws
                || snapshot.CurrentTurnScore < 0 || snapshot.CurrentTurnScore > 180) return false;
            Performance = new MatchPerformance
            {
                Throws = snapshot.Throws,
                ScoringHits = snapshot.ScoringHits,
                CountedScore = snapshot.CountedScore,
                BestTurn = snapshot.BestTurn,
                BestCheckout = snapshot.BestCheckout,
                Bulls = snapshot.Bulls,
                Triples = snapshot.Triples
            };
            _turnScore = snapshot.CurrentTurnScore;
            return true;
        }
    }
}
