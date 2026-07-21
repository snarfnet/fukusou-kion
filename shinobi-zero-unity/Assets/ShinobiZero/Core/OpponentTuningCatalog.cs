using System;

namespace ShinobiZero.Core
{
    public struct OpponentTuning
    {
        public readonly float Skill;
        public readonly int PreferredBase;
        public readonly float ThinkTime;
        public readonly float Aggression;
        public readonly float PressureResistance;
        public readonly float Consistency;
        public readonly float HorizontalBias;
        public readonly OpponentStrategy Strategy;

        public OpponentTuning(float skill, int preferredBase, float thinkTime, float aggression, float pressureResistance,
            float consistency, float horizontalBias, OpponentStrategy strategy)
        {
            Skill = skill; PreferredBase = preferredBase; ThinkTime = thinkTime; Aggression = aggression;
            PressureResistance = pressureResistance; Consistency = consistency; HorizontalBias = horizontalBias;
            Strategy = strategy;
        }
    }

    public static class OpponentTuningCatalog
    {
        private static readonly OpponentTuning[] Values =
        {
            new OpponentTuning(.34f, 19, 1.05f, .18f, .30f, .32f, -.035f, OpponentStrategy.Conservative),
            new OpponentTuning(.48f, 18, .90f, .35f, .50f, .47f, .025f, OpponentStrategy.Rhythm),
            new OpponentTuning(.62f, 20, .72f, .82f, .58f, .55f, -.012f, OpponentStrategy.Aggressive),
            new OpponentTuning(.77f, 19, .58f, .55f, .82f, .78f, .008f, OpponentStrategy.CheckoutSpecialist),
            new OpponentTuning(.91f, 20, .44f, .68f, .96f, .95f, 0f, OpponentStrategy.Adaptive)
        };

        public static int Count { get { return Values.Length; } }
        public static OpponentTuning Get(int index)
        {
            if (index < 0 || index >= Values.Length) throw new ArgumentOutOfRangeException("index");
            return Values[index];
        }
    }

    public struct AimPoint
    {
        public readonly float X;
        public readonly float Y;
        public AimPoint(float x, float y) { X = x; Y = y; }
    }

    public static class DartboardAimGeometry
    {
        public static AimPoint Point(AimTarget aim)
        {
            if (aim.Base == 25) return new AimPoint(0f, 0f);
            var index = -1;
            for (var i = 0; i < DartboardGeometry.ClockwiseNumbers.Length; i++)
                if (DartboardGeometry.ClockwiseNumbers[i] == aim.Base) { index = i; break; }
            if (index < 0) throw new ArgumentOutOfRangeException("aim", "Aim base is not on the board.");
            var angle = index * Math.PI / 10d;
            var radius = aim.Multiplier == 3 ? DartboardGeometry.TripleAimRadius
                : aim.Multiplier == 2 ? DartboardGeometry.DoubleAimRadius : .72d;
            return new AimPoint((float)(Math.Sin(angle) * radius), (float)(Math.Cos(angle) * radius));
        }
    }

    public static class OpponentBalanceSimulator
    {
        public static float ExpectedThreeDartScore(OpponentTuning tuning, int samples, uint seed)
        {
            if (samples <= 0) throw new ArgumentOutOfRangeException("samples");
            var brain = new OpponentBrain();
            var aim = brain.Choose(301, false, tuning.Skill, tuning.PreferredBase, tuning.Aggression, 3, tuning.Strategy);
            var point = DartboardAimGeometry.Point(aim);
            var sigma = OpponentAccuracyModel.Sigma(tuning.Skill, tuning.Consistency, tuning.PressureResistance, false, 3);
            var total = 0L;
            var state = seed == 0 ? 1u : seed;
            for (var i = 0; i < samples; i++)
            {
                var a = NextUniform(ref state);
                var b = NextUniform(ref state);
                var error = OpponentAccuracyModel.Sample(sigma, tuning.HorizontalBias, a, b);
                total += DartboardGeometry.Score(point.X + error.X, point.Y + error.Y).Score;
            }
            return total * 3f / samples;
        }

        private static float NextUniform(ref uint state)
        {
            state = unchecked(state * 1664525u + 1013904223u);
            return ((state >> 8) & 0x00FFFFFFu) / 16777216f;
        }
    }
}
