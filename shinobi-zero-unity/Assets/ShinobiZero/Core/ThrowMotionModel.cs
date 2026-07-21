using System;

namespace ShinobiZero.Core
{
    public struct ThrowMotionPose
    {
        public readonly float Shoulder;
        public readonly float Elbow;
        public readonly float Wrist;
        public readonly float Torso;
        public ThrowMotionPose(float shoulder, float elbow, float wrist, float torso)
        {
            Shoulder = shoulder; Elbow = elbow; Wrist = wrist; Torso = torso;
        }
    }

    public static class ThrowMotionModel
    {
        public static ThrowMotionPose Evaluate(float normalizedTime, float releaseTime, float windup, float followThrough)
        {
            normalizedTime = Clamp01(normalizedTime);
            releaseTime = Math.Max(.05f, Math.Min(.95f, releaseTime));
            if (normalizedTime < releaseTime)
            {
                var amount = Smooth(normalizedTime / releaseTime);
                return new ThrowMotionPose(-windup * amount, 44f * amount, -22f * amount, -8f * amount);
            }
            var follow = Smooth((normalizedTime - releaseTime) / (1f - releaseTime));
            return new ThrowMotionPose(
                Lerp(-windup, followThrough, follow), Lerp(44f, -18f, follow),
                Lerp(-22f, 36f, follow), Lerp(-8f, 7f, follow));
        }

        public static bool CrossedRelease(float previousTime, float currentTime, float releaseTime)
        {
            return previousTime < releaseTime && currentTime >= releaseTime;
        }

        private static float Smooth(float value) { value = Clamp01(value); return value * value * (3f - 2f * value); }
        private static float Clamp01(float value) { return Math.Max(0f, Math.Min(1f, value)); }
        private static float Lerp(float a, float b, float t) { return a + (b - a) * t; }
    }
}
