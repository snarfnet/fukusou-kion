using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class ScreenAimModelTests
    {
        [Test] public void BoardCenterMapsToZero()
        {
            var aim = ScreenAimModel.Map(500f, 900f, 500f, 900f, 300f);
            Assert.That(aim.X, Is.Zero);
            Assert.That(aim.Y, Is.Zero);
        }

        [Test] public void VisibleRingMapsToUnitRadius()
        {
            var right = ScreenAimModel.Map(800f, 900f, 500f, 900f, 300f);
            var top = ScreenAimModel.Map(500f, 1200f, 500f, 900f, 300f);
            Assert.That(right.X, Is.EqualTo(1f));
            Assert.That(top.Y, Is.EqualTo(1f));
        }

        [Test] public void FarPointerIsClampedWithoutChangingDirection()
        {
            var aim = ScreenAimModel.Map(1100f, 1500f, 500f, 900f, 300f);
            var length = System.Math.Sqrt(aim.X * aim.X + aim.Y * aim.Y);
            Assert.That(length, Is.EqualTo(1.25f).Within(.0001f));
            Assert.That(aim.X, Is.EqualTo(aim.Y).Within(.0001f));
        }

        [Test] public void InvalidProjectionFallsBackToCenter()
        {
            var aim = ScreenAimModel.Map(100f, 200f, 0f, 0f, 0f);
            Assert.That(aim.X, Is.Zero);
            Assert.That(aim.Y, Is.Zero);
        }
    }
}
