using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class ThrowPromptCatalogTests
    {
        [TestCase(TutorialInputMode.Touch, GameLanguage.Japanese, "払って")]
        [TestCase(TutorialInputMode.Gamepad, GameLanguage.Japanese, "RT")]
        [TestCase(TutorialInputMode.KeyboardMouse, GameLanguage.Japanese, "WASD")]
        [TestCase(TutorialInputMode.Touch, GameLanguage.English, "SWIPE")]
        [TestCase(TutorialInputMode.Gamepad, GameLanguage.English, "LEFT STICK")]
        [TestCase(TutorialInputMode.KeyboardMouse, GameLanguage.English, "RELEASE F")]
        public void PromptMatchesInputAndLanguage(TutorialInputMode mode, GameLanguage language, string expected) =>
            StringAssert.Contains(expected, ThrowPromptCatalog.Text(mode, language));

        [TestCase(TutorialInputMode.Gamepad, GameLanguage.Japanese, "L3")]
        [TestCase(TutorialInputMode.Gamepad, GameLanguage.English, "L3 RESET")]
        [TestCase(TutorialInputMode.KeyboardMouse, GameLanguage.Japanese, "Rで中央")]
        [TestCase(TutorialInputMode.KeyboardMouse, GameLanguage.English, "R RESET")]
        public void DesktopPromptKeepsAimResetVisible(TutorialInputMode mode, GameLanguage language, string expected) =>
            StringAssert.Contains(expected, ThrowPromptCatalog.Text(mode, language));
    }
}
