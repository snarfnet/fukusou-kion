using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class OpponentBalanceTests
    {
        [Test] public void FiveOpponentsHaveStrictlyIncreasingOpenScoring()
        {
            var previous = 0f;
            for (var i = 0; i < OpponentTuningCatalog.Count; i++)
            {
                var expected = OpponentBalanceSimulator.ExpectedThreeDartScore(OpponentTuningCatalog.Get(i), 20000, 1977u);
                Assert.That(expected, Is.GreaterThan(previous + 1f), "Opponent " + i + " must be measurably stronger");
                previous = expected;
            }
        }

        [Test] public void SimulationIsDeterministic()
        {
            var tuning = OpponentTuningCatalog.Get(4);
            var first = OpponentBalanceSimulator.ExpectedThreeDartScore(tuning, 5000, 42u);
            var second = OpponentBalanceSimulator.ExpectedThreeDartScore(tuning, 5000, 42u);
            Assert.That(first, Is.EqualTo(second));
        }

        [Test] public void AimGeometryMatchesScoringGeometry()
        {
            var point = DartboardAimGeometry.Point(new AimTarget(20, 3, 1f));
            Assert.That(DartboardGeometry.Score(point.X, point.Y).Score, Is.EqualTo(60));
        }
    }
}
