namespace ShinobiZero.Core
{
    public enum TutorialInputMode { Touch, Gamepad, KeyboardMouse }

    public static class TutorialThrowGuide
    {
        public static string Text(TutorialInputMode mode, GameLanguage language)
        {
            if (language == GameLanguage.English)
            {
                if (mode == TutorialInputMode.Gamepad)
                    return "Aim with the left stick. Hold RT to gather force,\nthen release to throw. The right stick adds spin.";
                if (mode == TutorialInputMode.KeyboardMouse)
                    return "Aim with WASD or the arrow keys. Hold F to gather force,\nthen release to throw. You can also swipe with the mouse.";
                return "Place your finger low, take aim,\nthen swipe upward with intent.\nSide movement changes spin and impact.";
            }

            if (mode == TutorialInputMode.Gamepad)
                return "左スティックで狙い、RTを長押しして力を溜め、\n離すと投げます。右スティックで回転を加えます。";
            if (mode == TutorialInputMode.KeyboardMouse)
                return "WASDか矢印キーで狙い、Fを長押しして力を溜め、\n離すと投げます。マウスのスワイプでも投げられます。";
            return "画面の下に指を置き、狙いを定めて\n上へ素早く払います。\n横方向の動きは回転と着弾に影響します。";
        }
    }
}
