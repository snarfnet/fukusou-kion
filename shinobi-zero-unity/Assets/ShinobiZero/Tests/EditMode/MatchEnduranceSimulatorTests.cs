using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class MatchEnduranceSimulatorTests
    {
        [Test] public void ThousandsOfMatchesTerminateWithoutInvariantFailure()
        {
            var report = MatchEnduranceSimulator.Run(3200, 0x5A17u);
            Assert.That(report.Matches, Is.EqualTo(3200));
            Assert.That(report.Throws, Is.GreaterThan(report.Matches * 3));
            Assert.That(report.Legs, Is.GreaterThanOrEqualTo(report.Matches));
            Assert.That(report.Busts, Is.GreaterThan(0));
            Assert.That(report.MaximumThrowsInMatch, Is.LessThan(600));
        }

        [Test] public void SimulationIsDeterministic()
        {
            var first = MatchEnduranceSimulator.Run(64, 42u);
            var second = MatchEnduranceSimulator.Run(64, 42u);
            Assert.That(second.Throws, Is.EqualTo(first.Throws));
            Assert.That(second.Busts, Is.EqualTo(first.Busts));
            Assert.That(second.Legs, Is.EqualTo(first.Legs));
        }
    }
}
