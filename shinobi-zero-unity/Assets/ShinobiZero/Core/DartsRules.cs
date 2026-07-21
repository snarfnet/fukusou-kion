namespace ShinobiZero.Core
{
    public struct DartHit
    {
        public readonly int Base;
        public readonly int Multiplier;
        public int Score { get { return Base * Multiplier; } }
        public bool IsDouble { get { return Multiplier == 2; } }

        public DartHit(int baseValue, int multiplier)
        {
            Base = baseValue;
            Multiplier = multiplier;
        }

        public static DartHit Miss { get { return new DartHit(0, 0); } }
        public static DartHit OuterBull { get { return new DartHit(25, 1); } }
        public static DartHit Bull { get { return new DartHit(25, 2); } }
    }

    public struct ScoreResolution
    {
        public readonly int Remaining;
        public readonly bool Bust;
        public readonly bool InvalidCheckout;
        public readonly bool Win;

        public ScoreResolution(int remaining, bool bust, bool invalidCheckout, bool win)
        {
            Remaining = remaining;
            Bust = bust;
            InvalidCheckout = invalidCheckout;
            Win = win;
        }
    }

    public static class DartsRules
    {
        public static ScoreResolution Resolve(int remaining, int turnStart, DartHit hit, bool doubleOut)
        {
            var next = remaining - hit.Score;
            var invalidCheckout = next == 0 && doubleOut && !hit.IsDouble;
            var bust = next < 0 || (doubleOut && next == 1) || invalidCheckout;
            return bust
                ? new ScoreResolution(turnStart, true, invalidCheckout, false)
                : new ScoreResolution(next, false, false, next == 0);
        }
    }
}
