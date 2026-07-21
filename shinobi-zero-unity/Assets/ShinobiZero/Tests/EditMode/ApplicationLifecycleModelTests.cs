using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class ApplicationLifecycleModelTests
    {
        [TestCase(true, false, false, false)]
        [TestCase(false, false, false, true)]
        [TestCase(true, true, false, true)]
        [TestCase(true, false, true, true)]
        [TestCase(false, true, true, true)]
        public void AudioFollowsAllLifecycleSources(bool focused, bool suspended, bool matchPaused, bool expected) =>
            Assert.That(ApplicationLifecycleModel.ShouldPauseAudio(focused, suspended, matchPaused), Is.EqualTo(expected));

        [Test] public void FocusReturnDoesNotOverridePausedMatch()
        {
            Assert.That(ApplicationLifecycleModel.ShouldPauseAudio(true, false, true), Is.True);
        }

        [Test] public void PlatformOverlayAlwaysPausesAudio()
        {
            Assert.That(ApplicationLifecycleModel.ShouldPauseAudio(true, false, false, true), Is.True);
        }

        [Test] public void ResumeRequiresClearForegroundState()
        {
            Assert.That(ApplicationLifecycleModel.CanResume(true, false, false), Is.True);
            Assert.That(ApplicationLifecycleModel.CanResume(false, false, false), Is.False);
            Assert.That(ApplicationLifecycleModel.CanResume(true, true, false), Is.False);
            Assert.That(ApplicationLifecycleModel.CanResume(true, false, true), Is.False);
        }
    }
}
