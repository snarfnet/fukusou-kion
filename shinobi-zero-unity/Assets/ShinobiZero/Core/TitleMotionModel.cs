using System;

namespace ShinobiZero.Core
{
    public struct TitleMotionState
    {
        public readonly float Scale;
        public readonly float X;
        public readonly float Y;

        public TitleMotionState(float scale, float x, float y)
        {
            Scale = scale;
            X = x;
            Y = y;
        }
    }

    public static class TitleMotionModel
    {
        public static TitleMotionState Evaluate(float seconds, bool landscape, bool reducedMotion)
        {
            if (reducedMotion) return new TitleMotionState(1f, 0f, 0f);
            var phase = seconds * .11f;
            var scale = 1.022f + (float)Math.Sin(phase) * .004f;
            var x = (float)Math.Sin(phase * .73f) * (landscape ? 13f : 8f);
            var y = (float)Math.Cos(phase * .57f) * (landscape ? 4f : 7f);
            return new TitleMotionState(scale, x, y);
        }
    }
}
