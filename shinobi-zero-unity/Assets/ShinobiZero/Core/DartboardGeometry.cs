using System;

namespace ShinobiZero.Core
{
    public static class DartboardGeometry
    {
        public const double InnerBullRadius = 6.35d / 170d;
        public const double OuterBullRadius = 15.9d / 170d;
        public const double TripleInnerRadius = 99d / 170d;
        public const double TripleOuterRadius = 107d / 170d;
        public const double DoubleInnerRadius = 162d / 170d;
        public const double DoubleOuterRadius = 1d;
        public const double TripleAimRadius = 103d / 170d;
        public const double DoubleAimRadius = 166d / 170d;
        public static readonly int[] ClockwiseNumbers =
        {
            20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5
        };

        public static DartHit Score(float normalizedX, float normalizedY)
        {
            var distance = Math.Sqrt(normalizedX * normalizedX + normalizedY * normalizedY);
            if (distance > DoubleOuterRadius) return DartHit.Miss;
            if (distance <= InnerBullRadius) return DartHit.Bull;
            if (distance <= OuterBullRadius) return DartHit.OuterBull;

            var angle = Math.Atan2(normalizedX, normalizedY);
            if (angle < 0d) angle += Math.PI * 2d;
            var sector = (int)Math.Floor((angle + Math.PI / 20d) / (Math.PI / 10d)) % 20;
            var baseValue = ClockwiseNumbers[sector];
            if (distance >= DoubleInnerRadius) return new DartHit(baseValue, 2);
            if (distance >= TripleInnerRadius && distance <= TripleOuterRadius) return new DartHit(baseValue, 3);
            return new DartHit(baseValue, 1);
        }
    }
}
