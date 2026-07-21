using System;

namespace ShinobiZero.Core
{
    public struct ButtonThrowSolution
    {
        public readonly bool Valid;
        public readonly float BoardX;
        public readonly float BoardY;
        public readonly float Power;
        public readonly float Spin;
        public ButtonThrowSolution(bool valid, float boardX, float boardY, float power, float spin)
        {
            Valid = valid; BoardX = boardX; BoardY = boardY; Power = power; Spin = spin;
        }
    }

    public static class ButtonThrowModel
    {
        public static ButtonThrowSolution Map(float aimX, float aimY, float holdDuration, float spinInput)
        {
            if (holdDuration < .08f || holdDuration > 1.4f)
                return new ButtonThrowSolution(false, aimX, aimY, 0f, 0f);
            var charge = Clamp(holdDuration / .48f, 0f, 1f);
            var power = charge * charge * (3f - 2f * charge);
            var timingError = holdDuration - .48f;
            var boardY = aimY - timingError * .22f;
            var spin = Clamp(spinInput, -1f, 1f) * 24f;
            var length = Math.Sqrt(aimX * aimX + boardY * boardY);
            if (length > 1.25d)
            {
                var scale = 1.25d / length;
                aimX = (float)(aimX * scale);
                boardY = (float)(boardY * scale);
            }
            return new ButtonThrowSolution(true, aimX, boardY, power, spin);
        }

        private static float Clamp(float value, float minimum, float maximum)
        {
            return Math.Max(minimum, Math.Min(maximum, value));
        }
    }

    public static class GamepadInputTuning
    {
        public const float DeadzoneMinimum = .18f;
        public const float DeadzoneMaximum = .95f;
    }
}
