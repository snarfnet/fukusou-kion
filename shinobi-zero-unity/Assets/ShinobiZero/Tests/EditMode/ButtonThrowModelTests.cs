using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class ButtonThrowModelTests
    {
        [TestCase(.01f)]
        [TestCase(1.5f)]
        public void InvalidHoldIsRejected(float duration) => Assert.That(
            ButtonThrowModel.Map(0f, 0f, duration, 0f).Valid, Is.False);

        [Test] public void IdealHoldPreservesAim()
        {
            var result = ButtonThrowModel.Map(.3f, -.2f, .48f, 0f);
            Assert.That(result.Valid, Is.True);
            Assert.That(result.BoardX, Is.EqualTo(.3f));
            Assert.That(result.BoardY, Is.EqualTo(-.2f).Within(.0001f));
            Assert.That(result.Power, Is.EqualTo(1f));
        }

        [Test] public void LongHoldDropsThrowSlightly() => Assert.That(
            ButtonThrowModel.Map(0f, 0f, .8f, 0f).BoardY, Is.LessThan(0f));

        [Test] public void StickControlsSpin() => Assert.That(
            ButtonThrowModel.Map(0f, 0f, .48f, 1f).Spin, Is.EqualTo(24f));

        [Test] public void AimIsClampedToPlayableRadius()
        {
            var result = ButtonThrowModel.Map(2f, 2f, .48f, 0f);
            var length = System.Math.Sqrt(result.BoardX * result.BoardX + result.BoardY * result.BoardY);
            Assert.That(length, Is.EqualTo(1.25f).Within(.0001f));
        }
    }
}
