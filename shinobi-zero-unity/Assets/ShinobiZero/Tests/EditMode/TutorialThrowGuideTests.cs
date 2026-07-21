using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class TutorialThrowGuideTests
    {
        [TestCase(TutorialInputMode.Touch, GameLanguage.Japanese, "指")]
        [TestCase(TutorialInputMode.Gamepad, GameLanguage.Japanese, "RT")]
        [TestCase(TutorialInputMode.KeyboardMouse, GameLanguage.Japanese, "WASD")]
        [TestCase(TutorialInputMode.Touch, GameLanguage.English, "finger")]
        [TestCase(TutorialInputMode.Gamepad, GameLanguage.English, "left stick")]
        [TestCase(TutorialInputMode.KeyboardMouse, GameLanguage.English, "WASD")]
        public void GuideMatchesActiveInput(TutorialInputMode mode, GameLanguage language, string expected) =>
            StringAssert.Contains(expected, TutorialThrowGuide.Text(mode, language));

        [TestCase(TutorialInputMode.Gamepad, GameLanguage.Japanese, "L3")]
        [TestCase(TutorialInputMode.Gamepad, GameLanguage.English, "L3")]
        [TestCase(TutorialInputMode.KeyboardMouse, GameLanguage.Japanese, "Rで中央")]
        [TestCase(TutorialInputMode.KeyboardMouse, GameLanguage.English, "R to reset")]
        public void DesktopGuideExplainsAimReset(TutorialInputMode mode, GameLanguage language, string expected) =>
            StringAssert.Contains(expected, TutorialThrowGuide.Text(mode, language));
    }
}
