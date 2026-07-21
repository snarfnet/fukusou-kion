using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class PlayerThrowMotionModelTests
    {
        [Test] public void StrongThrowIsFasterWithLargerFollowThrough()
        {
            var soft = PlayerThrowMotionModel.Tune(.1f, 0f, false);
            var strong = PlayerThrowMotionModel.Tune(.95f, 0f, false);
            Assert.That(strong.Duration, Is.LessThan(soft.Duration));
            Assert.That(strong.FollowThrough, Is.GreaterThan(soft.FollowThrough));
            Assert.That(strong.Windup, Is.GreaterThan(soft.Windup));
        }

        [Test] public void SpinChangesWristDirection()
        {
            Assert.That(PlayerThrowMotionModel.Tune(.5f, 500f, false).WristBias, Is.GreaterThan(0f));
            Assert.That(PlayerThrowMotionModel.Tune(.5f, -500f, false).WristBias, Is.LessThan(0f));
        }

        [Test] public void ReducedMotionShortensAndSoftensGesture()
        {
            var full = PlayerThrowMotionModel.Tune(.8f, 400f, false);
            var reduced = PlayerThrowMotionModel.Tune(.8f, 400f, true);
            Assert.That(reduced.Duration, Is.LessThan(full.Duration));
            Assert.That(reduced.Windup, Is.LessThan(full.Windup * .4f));
            Assert.That(reduced.WristBias, Is.LessThan(full.WristBias * .4f));
        }

        [Test] public void InputsAreClamped()
        {
            var maximum = PlayerThrowMotionModel.Tune(1f, 720f, false);
            var overflow = PlayerThrowMotionModel.Tune(8f, 9000f, false);
            Assert.That(overflow.Duration, Is.EqualTo(maximum.Duration));
            Assert.That(overflow.WristBias, Is.EqualTo(maximum.WristBias));
        }
    }
}
