using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class ThrowInputModelTests
    {
        [Test]
        public void IdealRiseMapsToAimAnchor()
        {
            var result = ThrowInputModel.Map(0f, .34f, .35f, .1f, -.1f, .34f, 1f, 1.1f, 45f);
            Assert.That(result.BoardX, Is.EqualTo(.1f).Within(.0001f));
            Assert.That(result.BoardY, Is.EqualTo(-.1f).Within(.0001f));
            Assert.That(result.Power, Is.EqualTo(1f).Within(.0001f));
        }

        [Test] public void SlowDragIsRejected() => Assert.That(
            ThrowInputModel.IsValid(.1f, 1.2f, .08f, .18f, 1.4f), Is.False);

        [Test] public void DeliberateFlickIsAccepted() => Assert.That(
            ThrowInputModel.IsValid(.2f, .35f, .08f, .18f, 1.4f), Is.True);

        [Test]
        public void HorizontalMotionControlsAimAndSpin()
        {
            var result = ThrowInputModel.Map(.12f, .34f, .3f, 0f, 0f, .34f, 1f, 1.1f, 45f);
            Assert.That(result.BoardX, Is.EqualTo(.12f).Within(.0001f));
            Assert.That(result.Spin, Is.GreaterThan(0f));
        }

        [Test]
        public void EquivalentNormalizedGesturesProduceSameResult()
        {
            var compactPhoneRise = 227f / 667f;
            var largePhoneRise = 317f / 932f;
            var first = ThrowInputModel.Map(0f, compactPhoneRise, .35f, 0f, 0f, .34f, 1f, 1.1f, 45f);
            var second = ThrowInputModel.Map(0f, largePhoneRise, .35f, 0f, 0f, .34f, 1f, 1.1f, 45f);
            Assert.That(first.BoardY, Is.EqualTo(second.BoardY).Within(.002f));
        }
    }
}
