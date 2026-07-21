using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class ThrowCalibrationModelTests
    {
        [Test] public void UsesMedianToIgnoreOneWildThrow() => Assert.That(
            ThrowCalibrationModel.ComputeIdeal(new[] { .34f, .35f, .9f }), Is.EqualTo(.35f).Within(.0001f));

        [Test] public void ClampsVeryShortMotion() => Assert.That(
            ThrowCalibrationModel.ComputeIdeal(new[] { .1f, .12f, .14f }), Is.EqualTo(.22f).Within(.0001f));

        [Test] public void ClampsVeryLongMotion() => Assert.That(
            ThrowCalibrationModel.ComputeIdeal(new[] { .6f, .7f, .8f }), Is.EqualTo(.48f).Within(.0001f));

        [Test] public void RequiresThreeThrows() => Assert.Throws<System.ArgumentException>(() =>
            ThrowCalibrationModel.ComputeIdeal(new[] { .3f, .35f }));
    }
}
