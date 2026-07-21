using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class HapticPulseModelTests
    {
        [TestCase(HapticCue.Light)]
        [TestCase(HapticCue.Medium)]
        [TestCase(HapticCue.Success)]
        [TestCase(HapticCue.Error)]
        public void EveryCueIsBounded(HapticCue cue)
        {
            var pulse = HapticPulseModel.Get(cue);
            Assert.That(pulse.LowFrequency, Is.InRange(0f, 1f));
            Assert.That(pulse.HighFrequency, Is.InRange(0f, 1f));
            Assert.That(pulse.Duration, Is.InRange(.01f, .25f));
        }

        [Test] public void SuccessIsLongerThanOrdinaryImpact() => Assert.That(
            HapticPulseModel.Get(HapticCue.Success).Duration,
            Is.GreaterThan(HapticPulseModel.Get(HapticCue.Medium).Duration));

        [Test] public void ErrorUsesHeavierLowFrequencyMotor()
        {
            var error = HapticPulseModel.Get(HapticCue.Error);
            Assert.That(error.LowFrequency, Is.GreaterThan(error.HighFrequency));
        }

        [Test] public void LightCueFavorsCrispHighFrequencyMotor()
        {
            var light = HapticPulseModel.Get(HapticCue.Light);
            Assert.That(light.HighFrequency, Is.GreaterThan(light.LowFrequency));
        }
    }
}
