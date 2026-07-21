namespace ShinobiZero.Core
{
    public static class ThrowPromptCatalog
    {
        public static string Text(TutorialInputMode mode, GameLanguage language)
        {
            if (language == GameLanguage.English)
            {
                if (mode == TutorialInputMode.Gamepad) return "LEFT STICK AIM · L3 RESET · RELEASE RT THROW";
                if (mode == TutorialInputMode.KeyboardMouse) return "WASD AIM · R RESET · RELEASE F THROW";
                return "SWIPE UP TO THROW";
            }
            if (mode == TutorialInputMode.Gamepad) return "左スティック照準　L3で中央　RTを離して投げる";
            if (mode == TutorialInputMode.KeyboardMouse) return "WASD照準　Rで中央　Fを離して投げる";
            return "下から上へ払って投げる";
        }
    }
}
