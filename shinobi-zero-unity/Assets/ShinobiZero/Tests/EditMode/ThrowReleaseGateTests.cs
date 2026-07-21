using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class ThrowReleaseGateTests
    {
        [Test] public void OneArmAllowsExactlyOneRelease()
        {
            var gate = new ThrowReleaseGate();
            gate.Arm();
            Assert.That(gate.TryRelease(), Is.True);
            Assert.That(gate.TryRelease(), Is.False);
        }

        [Test] public void RearmingAllowsTheNextThrow()
        {
            var gate = new ThrowReleaseGate();
            gate.Arm();
            gate.TryRelease();
            gate.Arm();
            Assert.That(gate.TryRelease(), Is.True);
        }

        [Test] public void ResetCancelsARelease()
        {
            var gate = new ThrowReleaseGate();
            gate.Arm();
            gate.Reset();
            Assert.That(gate.TryRelease(), Is.False);
        }
    }
}
