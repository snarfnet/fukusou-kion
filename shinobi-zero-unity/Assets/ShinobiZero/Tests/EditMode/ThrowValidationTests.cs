using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class ThrowValidationTests
    {
        [Test] public void DownwardMotionReportsWrongDirection() => Assert.That(
            ThrowInputModel.Validate(-.1f, .3f, .08f, .18f, 1.4f), Is.EqualTo(ThrowRejectionReason.WrongDirection));

        [Test] public void SmallMotionReportsTooShort() => Assert.That(
            ThrowInputModel.Validate(.04f, .1f, .08f, .18f, 1.4f), Is.EqualTo(ThrowRejectionReason.TooShort));

        [Test] public void SlowMotionReportsTooSlow() => Assert.That(
            ThrowInputModel.Validate(.1f, 1f, .08f, .18f, 1.4f), Is.EqualTo(ThrowRejectionReason.TooSlow));

        [Test] public void HeldGestureReportsTooLong() => Assert.That(
            ThrowInputModel.Validate(.3f, 1.5f, .08f, .18f, 1.4f), Is.EqualTo(ThrowRejectionReason.TooLong));

        [Test] public void DeliberateFlickIsAccepted() => Assert.That(
            ThrowInputModel.Validate(.2f, .35f, .08f, .18f, 1.4f), Is.EqualTo(ThrowRejectionReason.None));
    }
}
