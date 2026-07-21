namespace ShinobiZero.Core
{
    public enum HapticCue { Light, Medium, Success, Error }

    public struct HapticPulse
    {
        public readonly float LowFrequency;
        public readonly float HighFrequency;
        public readonly float Duration;

        public HapticPulse(float lowFrequency, float highFrequency, float duration)
        {
            LowFrequency = lowFrequency;
            HighFrequency = highFrequency;
            Duration = duration;
        }
    }

    public static class HapticPulseModel
    {
        public static HapticPulse Get(HapticCue cue)
        {
            if (cue == HapticCue.Light) return new HapticPulse(.08f, .22f, .045f);
            if (cue == HapticCue.Medium) return new HapticPulse(.28f, .62f, .095f);
            if (cue == HapticCue.Success) return new HapticPulse(.52f, .82f, .19f);
            return new HapticPulse(.72f, .2f, .18f);
        }
    }
}
