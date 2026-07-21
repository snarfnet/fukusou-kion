using System;

namespace ShinobiZero.Core
{
    public static class ThrowCalibrationModel
    {
        public const float MinimumIdealRise = .22f;
        public const float MaximumIdealRise = .48f;

        public static float ComputeIdeal(float[] riseFractions)
        {
            if (riseFractions == null || riseFractions.Length < 3)
                throw new ArgumentException("At least three calibration throws are required.", "riseFractions");
            var sorted = (float[])riseFractions.Clone();
            Array.Sort(sorted);
            var middle = sorted.Length / 2;
            var median = sorted.Length % 2 == 1
                ? sorted[middle]
                : (sorted[middle - 1] + sorted[middle]) * .5f;
            return Math.Max(MinimumIdealRise, Math.Min(MaximumIdealRise, median));
        }
    }
}
