using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class PerformanceGovernorTests
    {
        [Test] public void ThreeSlowWindowsLowerQuality()
        {
            var governor = new PerformanceGovernor(RuntimeQualityTier.High);
            Assert.That(governor.Sample(22f), Is.False);
            Assert.That(governor.Sample(22f), Is.False);
            Assert.That(governor.Sample(22f), Is.True);
            Assert.That(governor.Tier, Is.EqualTo(RuntimeQualityTier.Balanced));
        }

        [Test] public void SingleSpikeDoesNotLowerQuality()
        {
            var governor = new PerformanceGovernor(RuntimeQualityTier.High);
            governor.Sample(30f);
            governor.Sample(16.7f);
            governor.Sample(30f);
            Assert.That(governor.Tier, Is.EqualTo(RuntimeQualityTier.High));
        }

        [Test] public void RecoveryRequiresTwelveStableWindows()
        {
            var governor = new PerformanceGovernor(RuntimeQualityTier.Performance);
            for (var i = 0; i < 11; i++) Assert.That(governor.Sample(16.7f), Is.False);
            Assert.That(governor.Sample(16.7f), Is.True);
            Assert.That(governor.Tier, Is.EqualTo(RuntimeQualityTier.Balanced));
        }

        [Test] public void CannotMoveOutsideTierBounds()
        {
            var low = new PerformanceGovernor(RuntimeQualityTier.Performance);
            for (var i = 0; i < 20; i++) low.Sample(40f);
            Assert.That(low.Tier, Is.EqualTo(RuntimeQualityTier.Performance));
            var high = new PerformanceGovernor(RuntimeQualityTier.High);
            for (var i = 0; i < 20; i++) high.Sample(10f);
            Assert.That(high.Tier, Is.EqualTo(RuntimeQualityTier.High));
        }

        [TestCase(2000, 512, true, RuntimeQualityTier.Performance)]
        [TestCase(3000, 0, true, RuntimeQualityTier.Balanced)]
        [TestCase(6000, 2048, true, RuntimeQualityTier.High)]
        [TestCase(16000, 0, false, RuntimeQualityTier.High)]
        public void HardwareSelectsSafeInitialTier(int memory, int graphics, bool mobile, RuntimeQualityTier expected) =>
            Assert.That(PerformanceGovernor.InitialTier(memory, graphics, mobile), Is.EqualTo(expected));

        [Test] public void InvalidFrameTimeIsRejected() => Assert.Throws<System.ArgumentOutOfRangeException>(() =>
            new PerformanceGovernor(RuntimeQualityTier.High).Sample(0f));

        [Test] public void MemoryPressureDropsDirectlyToPerformance()
        {
            var governor = new PerformanceGovernor(RuntimeQualityTier.High);
            Assert.That(governor.HandleMemoryPressure(), Is.True);
            Assert.That(governor.Tier, Is.EqualTo(RuntimeQualityTier.Performance));
        }

        [Test] public void MemoryPressureStillRequiresStableRecoveryWindow()
        {
            var governor = new PerformanceGovernor(RuntimeQualityTier.High);
            governor.HandleMemoryPressure();
            for (var i = 0; i < 11; i++) Assert.That(governor.Sample(16.7f), Is.False);
            Assert.That(governor.Tier, Is.EqualTo(RuntimeQualityTier.Performance));
            Assert.That(governor.Sample(16.7f), Is.True);
            Assert.That(governor.Tier, Is.EqualTo(RuntimeQualityTier.Balanced));
        }
    }
}
