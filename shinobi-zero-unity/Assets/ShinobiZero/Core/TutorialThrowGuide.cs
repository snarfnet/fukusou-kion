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
                    return "Aim with the left stick. Press L3 to reset aim.\nHold RT, then release to throw. The right stick adds spin.";
                if (mode == TutorialInputMode.KeyboardMouse)
                    return "Aim with WASD or the arrow keys. Press R to reset aim.\nHold F, then release to throw. You can also swipe with the mouse.";
                return "Place your finger low, take aim,\nthen swipe upward with intent.\nSide movement changes spin and impact.";
            }

            if (mode == TutorialInputMode.Gamepad)
                return "左スティックで狙い、L3で中央へ戻します。\nRTを長押しして離すと投げ、右スティックで回転を加えます。";
            if (mode == TutorialInputMode.KeyboardMouse)
                return "WASDか矢印キーで狙い、Rで中央へ戻します。\nFを長押しして離すと投げ、マウスのスワイプも使えます。";
            return "画面の下に指を置き、狙いを定めて\n上へ素早く払います。\n横方向の動きは回転と着弾に影響します。";
        }
    }
}
