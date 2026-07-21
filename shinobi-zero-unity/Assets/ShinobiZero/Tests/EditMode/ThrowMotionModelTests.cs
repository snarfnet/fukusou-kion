using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class ThrowMotionModelTests
    {
        [Test] public void StartsAtRest()
        {
            var pose = ThrowMotionModel.Evaluate(0f, .6f, 50f, 70f);
            Assert.That(pose.Shoulder, Is.Zero);
        }

        [Test] public void ReachesWindupAtRelease()
        {
            var pose = ThrowMotionModel.Evaluate(.5999f, .6f, 50f, 70f);
            Assert.That(pose.Shoulder, Is.EqualTo(-50f).Within(.01f));
        }

        [Test] public void EndsInFollowThrough()
        {
            var pose = ThrowMotionModel.Evaluate(1f, .6f, 50f, 70f);
            Assert.That(pose.Shoulder, Is.EqualTo(70f).Within(.001f));
            Assert.That(pose.Wrist, Is.EqualTo(36f).Within(.001f));
        }

        [Test] public void ReleaseOnlyTriggersWhenThresholdIsCrossed()
        {
            Assert.That(ThrowMotionModel.CrossedRelease(.59f, .61f, .6f), Is.True);
            Assert.That(ThrowMotionModel.CrossedRelease(.61f, .7f, .6f), Is.False);
        }
    }
}
