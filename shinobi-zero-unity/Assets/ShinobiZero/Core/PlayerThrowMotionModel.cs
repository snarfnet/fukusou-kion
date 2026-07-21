using System;

namespace ShinobiZero.Core
{
    public struct PlayerThrowMotionTuning
    {
        public readonly float Duration;
        public readonly float ReleaseTime;
        public readonly float Windup;
        public readonly float FollowThrough;
        public readonly float WristBias;

        public PlayerThrowMotionTuning(float duration, float releaseTime, float windup, float followThrough, float wristBias)
        {
            Duration = duration;
            ReleaseTime = releaseTime;
            Windup = windup;
            FollowThrough = followThrough;
            WristBias = wristBias;
        }
    }

    public static class PlayerThrowMotionModel
    {
        public static PlayerThrowMotionTuning Tune(float power, float spin, bool reducedMotion)
        {
            power = Math.Max(0f, Math.Min(1f, power));
            spin = Math.Max(-720f, Math.Min(720f, spin));
            var scale = reducedMotion ? .32f : 1f;
            return new PlayerThrowMotionTuning(
                reducedMotion ? .12f : Lerp(.38f, .24f, power),
                reducedMotion ? .5f : Lerp(.62f, .53f, power),
                Lerp(42f, 72f, power) * scale,
                Lerp(54f, 88f, power) * scale,
                spin / 720f * 28f * scale);
        }

        private static float Lerp(float a, float b, float value) { return a + (b - a) * value; }
    }
}
