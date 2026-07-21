using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class ScreenWakePolicyTests
    {
        [Test] public void ActiveForegroundMatchPreventsSleep()
        {
            Assert.That(ScreenWakePolicy.ShouldPreventSleep(true, false, false, true, false), Is.True);
        }

        [TestCase(false, false, false, true, false)]
        [TestCase(true, true, false, true, false)]
        [TestCase(true, false, true, true, false)]
        [TestCase(true, false, false, false, false)]
        [TestCase(true, false, false, true, true)]
        public void MenusAndInterruptedMatchesFollowSystemSleep(bool active, bool finished, bool paused, bool focused, bool suspended)
        {
            Assert.That(ScreenWakePolicy.ShouldPreventSleep(active, finished, paused, focused, suspended), Is.False);
        }
    }
}
