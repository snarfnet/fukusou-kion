namespace ShinobiZero.Core
{
    public static class ThrowPromptCatalog
    {
        public static string Text(TutorialInputMode mode, GameLanguage language)
        {
            if (language == GameLanguage.English)
            {
                if (mode == TutorialInputMode.Gamepad) return "AIM WITH LEFT STICK · RELEASE RT TO THROW";
                if (mode == TutorialInputMode.KeyboardMouse) return "AIM WITH WASD · RELEASE F TO THROW";
                return "SWIPE UP TO THROW";
            }
            if (mode == TutorialInputMode.Gamepad) return "左スティックで狙う　RTを離して投げる";
            if (mode == TutorialInputMode.KeyboardMouse) return "WASDで狙う　Fを離して投げる";
            return "下から上へ払って投げる";
        }
    }
}
