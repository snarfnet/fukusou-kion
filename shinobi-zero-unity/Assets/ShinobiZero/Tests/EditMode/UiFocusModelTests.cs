using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class UiFocusModelTests
    {
        [Test] public void MatchWithoutOverlayHasNoUiFocus() =>
            Assert.That(UiFocusModel.Resolve(false, false, false, false, false, false), Is.EqualTo(UiFocusTarget.None));

        [Test] public void SelectionReceivesBaseFocus() =>
            Assert.That(UiFocusModel.Resolve(true, false, false, false, false, false), Is.EqualTo(UiFocusTarget.Selection));

        [Test] public void ResultOverridesSelection() =>
            Assert.That(UiFocusModel.Resolve(true, true, false, false, false, false), Is.EqualTo(UiFocusTarget.Result));

        [Test] public void SettingsOverridesLowerScreens() =>
            Assert.That(UiFocusModel.Resolve(true, true, true, true, true, false), Is.EqualTo(UiFocusTarget.Settings));

        [Test] public void PauseAlwaysWins() =>
            Assert.That(UiFocusModel.Resolve(true, true, true, true, true, true), Is.EqualTo(UiFocusTarget.Pause));

        [TestCase(false, false, false, false, UiBackTarget.None)]
        [TestCase(true, false, false, false, UiBackTarget.Result)]
        [TestCase(true, true, false, false, UiBackTarget.Calibration)]
        [TestCase(true, true, true, false, UiBackTarget.Tutorial)]
        [TestCase(true, true, true, true, UiBackTarget.Settings)]
        public void BackTargetsTopmostClosableScreen(bool result, bool calibration, bool tutorial, bool settings, UiBackTarget expected) =>
            Assert.That(UiFocusModel.ResolveBack(result, calibration, tutorial, settings), Is.EqualTo(expected));
    }
}
