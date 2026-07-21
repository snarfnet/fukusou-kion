using System;
using System.Collections.Generic;

namespace ShinobiZero.Core
{
    public sealed class TurnHistoryTracker
    {
        private readonly List<DartHit> _hits = new List<DartHit>(3);
        private Combatant? _thrower;
        private bool _resetBeforeNext;

        public Combatant? Thrower { get { return _thrower; } }
        public bool Bust { get; private set; }
        public int Count { get { return _hits.Count; } }
        public int Total
        {
            get
            {
                if (Bust) return 0;
                var total = 0;
                for (var i = 0; i < _hits.Count; i++) total += _hits[i].Score;
                return total;
            }
        }

        public void Reset()
        {
            _hits.Clear();
            _thrower = null;
            Bust = false;
            _resetBeforeNext = false;
        }

        public void Record(ThrowOutcome outcome)
        {
            if (_resetBeforeNext || !_thrower.HasValue || _thrower.Value != outcome.Thrower)
            {
                _hits.Clear();
                Bust = false;
                _resetBeforeNext = false;
            }
            _thrower = outcome.Thrower;
            if (_hits.Count >= 3) throw new InvalidOperationException("A darts turn cannot contain more than three throws.");
            _hits.Add(outcome.Hit);
            Bust = outcome.Score.Bust;
            if (outcome.LegEnded) _resetBeforeNext = true;
        }

        public DartHit HitAt(int index)
        {
            if (index < 0 || index >= _hits.Count) throw new ArgumentOutOfRangeException("index");
            return _hits[index];
        }
    }
}
