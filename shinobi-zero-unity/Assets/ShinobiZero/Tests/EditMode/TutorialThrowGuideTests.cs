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
    }
}
