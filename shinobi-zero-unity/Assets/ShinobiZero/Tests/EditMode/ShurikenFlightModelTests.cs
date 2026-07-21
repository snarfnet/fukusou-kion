using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class ShurikenFlightModelTests
    {
        [TestCase(1440f, 0f)]
        [TestCase(1440f, 360f)]
        [TestCase(-1440f, 0f)]
        public void AngularLimitAlwaysExceedsRequestedSpin(float baseSpeed, float bias)
        {
            var spin = ShurikenFlightModel.Spin(baseSpeed, bias);
            Assert.That(spin.RequiredAngularLimit, Is.GreaterThan(System.Math.Abs(spin.RadiansPerSecond)));
        }

        [Test] public void StandardThrowKeepsFourRevolutionsPerSecond()
        {
            var spin = ShurikenFlightModel.Spin(1440f, 0f);
            Assert.That(spin.RadiansPerSecond, Is.EqualTo(8f * System.Math.PI).Within(.001f));
        }
    }
}
