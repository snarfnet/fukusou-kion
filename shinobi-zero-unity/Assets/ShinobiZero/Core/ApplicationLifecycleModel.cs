namespace ShinobiZero.Core
{
    public static class ApplicationLifecycleModel
    {
        public static bool ShouldPauseAudio(bool applicationFocused, bool applicationSuspended, bool matchPaused, bool platformOverlay = false)
        {
            return !applicationFocused || applicationSuspended || matchPaused || platformOverlay;
        }

        public static bool CanResume(bool applicationFocused, bool applicationSuspended, bool platformOverlay)
        {
            return applicationFocused && !applicationSuspended && !platformOverlay;
        }
    }
}
