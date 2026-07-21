using System;

namespace ShinobiZero.Core
{
    public static class ImpactSettleModel
    {
        public static float Amplitude(float impactSpeed, float maximumDegrees)
        {
            if (impactSpeed <= 0f || maximumDegrees <= 0f) return 0f;
            return Math.Min(maximumDegrees, impactSpeed * .55f);
        }

        public static float Angle(float normalizedTime, float amplitudeDegrees)
        {
            var t = Math.Max(0f, Math.Min(1f, normalizedTime));
            var envelope = (1f - t) * (1f - t);
            return (float)(Math.Sin(t * Math.PI * 6d) * envelope * amplitudeDegrees);
        }
    }
}
