using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class TitleMotionModelTests
    {
        [Test] public void ReducedMotionIsPerfectlyStill()
        {
            var motion = TitleMotionModel.Evaluate(99f, false, true);
            Assert.That(motion.Scale, Is.EqualTo(1f));
            Assert.That(motion.X, Is.Zero);
            Assert.That(motion.Y, Is.Zero);
        }

        [Test] public void CinematicMotionRemainsSubtle()
        {
            for (var second = 0; second <= 120; second++)
            {
                var portrait = TitleMotionModel.Evaluate(second, false, false);
                var landscape = TitleMotionModel.Evaluate(second, true, false);
                Assert.That(portrait.Scale, Is.InRange(1.018f, 1.026f));
                Assert.That(System.Math.Abs(portrait.X), Is.LessThanOrEqualTo(8f));
                Assert.That(System.Math.Abs(portrait.Y), Is.LessThanOrEqualTo(7f));
                Assert.That(System.Math.Abs(landscape.X), Is.LessThanOrEqualTo(13f));
                Assert.That(System.Math.Abs(landscape.Y), Is.LessThanOrEqualTo(4f));
            }
        }
    }
}
