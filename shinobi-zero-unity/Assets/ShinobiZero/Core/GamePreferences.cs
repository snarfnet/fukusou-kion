namespace ShinobiZero.Core
{
    public struct GamePreferences
    {
        public readonly bool SoundEnabled;
        public readonly bool HapticsEnabled;
        public readonly bool ReducedMotion;
        public readonly bool EnglishUi;
        public readonly bool Fullscreen;

        public GamePreferences(bool soundEnabled, bool hapticsEnabled, bool reducedMotion, bool englishUi = false, bool fullscreen = true)
        {
            SoundEnabled = soundEnabled;
            HapticsEnabled = hapticsEnabled;
            ReducedMotion = reducedMotion;
            EnglishUi = englishUi;
            Fullscreen = fullscreen;
        }

        public static GamePreferences Default { get { return new GamePreferences(true, true, false); } }
    }

    public static class PreferencesCodec
    {
        private const int LegacyVersionFlag = 1 << 8;
        private const int VersionFlag = 1 << 9;

        public static int Encode(GamePreferences value)
        {
            return VersionFlag | (value.SoundEnabled ? 1 : 0) | (value.HapticsEnabled ? 2 : 0)
                | (value.ReducedMotion ? 4 : 0) | (value.EnglishUi ? 8 : 0) | (value.Fullscreen ? 16 : 0);
        }

        public static GamePreferences Decode(int value)
        {
            if ((value & VersionFlag) != 0)
                return new GamePreferences((value & 1) != 0, (value & 2) != 0, (value & 4) != 0, (value & 8) != 0, (value & 16) != 0);
            if ((value & LegacyVersionFlag) != 0)
                return new GamePreferences((value & 1) != 0, (value & 2) != 0, (value & 4) != 0, (value & 8) != 0, true);
            return GamePreferences.Default;
        }
    }
}
