using System;

namespace ShinobiZero.Core
{
    public struct AimError
    {
        public readonly float X;
        public readonly float Y;
        public AimError(float x, float y) { X = x; Y = y; }
    }

    public static class OpponentAccuracyModel
    {
        public static float Sigma(float skill, float consistency, float pressureResistance, bool checkoutPressure, int dartsLeft)
        {
            skill = Clamp01(skill);
            consistency = Clamp01(consistency);
            pressureResistance = Clamp01(pressureResistance);
            dartsLeft = Math.Max(1, Math.Min(3, dartsLeft));

            var baseSpread = .012f + .205f * (float)Math.Pow(1f - skill, 1.65);
            var consistencyFactor = 1.18f - consistency * .36f;
            var lateDartFactor = 1f + (3 - dartsLeft) * (1f - consistency) * .14f;
            var pressureFactor = checkoutPressure ? 1.52f - pressureResistance * .58f : 1f;
            return baseSpread * consistencyFactor * lateDartFactor * pressureFactor;
        }

        public static AimError Sample(float sigma, float horizontalBias, float uniformA, float uniformB)
        {
            uniformA = Math.Max(.0001f, Math.Min(.9999f, uniformA));
            uniformB = Math.Max(.0001f, Math.Min(.9999f, uniformB));
            var radius = Math.Sqrt(-2.0 * Math.Log(uniformA));
            var angle = Math.PI * 2.0 * uniformB;
            var x = (float)(radius * Math.Cos(angle)) * sigma + horizontalBias;
            var y = (float)(radius * Math.Sin(angle)) * sigma;
            return new AimError(x, y);
        }

        private static float Clamp01(float value) { return Math.Max(0f, Math.Min(1f, value)); }
    }
}
