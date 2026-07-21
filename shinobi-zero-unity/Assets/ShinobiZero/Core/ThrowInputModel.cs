using System;

namespace ShinobiZero.Core
{
    public enum ThrowRejectionReason { None, WrongDirection, TooShort, TooSlow, TooLong }

    public struct ThrowInputSolution
    {
        public readonly float BoardX;
        public readonly float BoardY;
        public readonly float Power;
        public readonly float Spin;

        public ThrowInputSolution(float boardX, float boardY, float power, float spin)
        {
            BoardX = boardX;
            BoardY = boardY;
            Power = power;
            Spin = spin;
        }
    }

    public static class ThrowInputModel
    {
        public static bool IsValid(float riseFraction, float duration, float minimumRise, float minimumSpeed, float maximumDuration)
        {
            return Validate(riseFraction, duration, minimumRise, minimumSpeed, maximumDuration) == ThrowRejectionReason.None;
        }

        public static ThrowRejectionReason Validate(float riseFraction, float duration, float minimumRise, float minimumSpeed, float maximumDuration)
        {
            if (duration > maximumDuration) return ThrowRejectionReason.TooLong;
            if (riseFraction <= 0f || duration <= 0f) return ThrowRejectionReason.WrongDirection;
            if (riseFraction < minimumRise) return ThrowRejectionReason.TooShort;
            if (riseFraction / duration < minimumSpeed) return ThrowRejectionReason.TooSlow;
            return ThrowRejectionReason.None;
        }

        public static ThrowInputSolution Map(
            float horizontalFraction,
            float riseFraction,
            float duration,
            float aimX,
            float aimY,
            float idealRiseFraction,
            float horizontalSensitivity,
            float verticalSensitivity,
            float spinSensitivity)
        {
            if (idealRiseFraction <= 0f) throw new ArgumentOutOfRangeException("idealRiseFraction");
            var riseRatio = Clamp(riseFraction / idealRiseFraction, 0f, 1.6f);
            var boardX = aimX + horizontalFraction * horizontalSensitivity;
            var boardY = aimY + (riseRatio - 1f) * verticalSensitivity;
            var powerT = Clamp(riseRatio, 0f, 1f);
            var power = powerT * powerT * (3f - 2f * powerT);
            var spin = duration <= 0f ? 0f : Clamp(horizontalFraction / duration * spinSensitivity, -30f, 30f);
            return new ThrowInputSolution(boardX, boardY, power, spin);
        }

        private static float Clamp(float value, float minimum, float maximum)
        {
            return Math.Max(minimum, Math.Min(maximum, value));
        }
    }
}
