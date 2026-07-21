namespace ShinobiZero.Core
{
    public static class ScreenWakePolicy
    {
        public static bool ShouldPreventSleep(bool matchActive, bool matchFinished, bool matchPaused,
            bool applicationFocused, bool applicationSuspended)
        {
            return matchActive && !matchFinished && !matchPaused && applicationFocused && !applicationSuspended;
        }
    }
}
