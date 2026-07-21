using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class ImpactSettleModelTests
    {
        [Test] public void FasterImpactProducesMoreWobbleUpToCap()
        {
            Assert.That(ImpactSettleModel.Amplitude(4f, 8f), Is.LessThan(ImpactSettleModel.Amplitude(12f, 8f)));
            Assert.That(ImpactSettleModel.Amplitude(100f, 8f), Is.EqualTo(8f));
        }

        [Test] public void WobbleStartsAndEndsAtRest()
        {
            Assert.That(ImpactSettleModel.Angle(0f, 8f), Is.EqualTo(0f).Within(.0001f));
            Assert.That(ImpactSettleModel.Angle(1f, 8f), Is.EqualTo(0f).Within(.0001f));
        }

        [Test] public void WobbleDecaysAcrossEquivalentPeaks()
        {
            Assert.That(System.Math.Abs(ImpactSettleModel.Angle(1f / 12f, 8f)),
                Is.GreaterThan(System.Math.Abs(ImpactSettleModel.Angle(5f / 12f, 8f))));
        }
    }
}
