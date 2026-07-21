using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class DartsRulesTests
    {
        [Test] public void DoubleTwentyChecksOutForty() => Assert.That(
            DartsRules.Resolve(40, 40, new DartHit(20, 2), true).Win, Is.True);

        [Test] public void SingleTwentyCannotDoubleOutForty()
        {
            var result = DartsRules.Resolve(20, 20, new DartHit(20, 1), true);
            Assert.That(result.Bust, Is.True);
            Assert.That(result.InvalidCheckout, Is.True);
            Assert.That(result.Remaining, Is.EqualTo(20));
        }

        [Test] public void BullCountsAsDoubleForCheckout() => Assert.That(
            DartsRules.Resolve(50, 50, DartHit.Bull, true).Win, Is.True);

        [Test] public void LeavingOneIsAllowedInStraightOut()
        {
            var result = DartsRules.Resolve(20, 60, new DartHit(19, 1), false);
            Assert.That(result.Remaining, Is.EqualTo(1));
            Assert.That(result.Bust, Is.False);
        }

        [Test] public void LeavingOneBustsInDoubleOut() => Assert.That(
            DartsRules.Resolve(20, 60, new DartHit(19, 1), true).Bust, Is.True);

        [Test] public void OverscoreRestoresTurnStart() => Assert.That(
            DartsRules.Resolve(10, 60, new DartHit(20, 1), false).Remaining, Is.EqualTo(60));

        [Test] public void BoardCentreScoresBull() => Assert.That(
            DartboardGeometry.Score(0f, 0f).Score, Is.EqualTo(50));

        [Test] public void TopTripleScoresSixty() => Assert.That(
            DartboardGeometry.Score(0f, (float)DartboardGeometry.TripleAimRadius).Score, Is.EqualTo(60));

        [Test] public void TopDoubleScoresForty() => Assert.That(
            DartboardGeometry.Score(0f, (float)DartboardGeometry.DoubleAimRadius).Score, Is.EqualTo(40));

        [Test] public void OutsideBoardMisses() => Assert.That(
            DartboardGeometry.Score(1.1f, 0f).Score, Is.Zero);

        [Test] public void EverySectorUsesOfficialClockwiseOrder()
        {
            for (var i = 0; i < DartboardGeometry.ClockwiseNumbers.Length; i++)
            {
                var angle = i * System.Math.PI / 10d;
                var x = (float)(System.Math.Sin(angle) * .4d);
                var y = (float)(System.Math.Cos(angle) * .4d);
                Assert.That(DartboardGeometry.Score(x, y).Base, Is.EqualTo(DartboardGeometry.ClockwiseNumbers[i]));
            }
        }

        [Test] public void StandardRingMeasurementsAreNormalizedToDoubleOuterEdge()
        {
            Assert.That(DartboardGeometry.InnerBullRadius * 170d, Is.EqualTo(6.35d).Within(.0001d));
            Assert.That(DartboardGeometry.TripleInnerRadius * 170d, Is.EqualTo(99d).Within(.0001d));
            Assert.That(DartboardGeometry.DoubleInnerRadius * 170d, Is.EqualTo(162d).Within(.0001d));
        }
    }
}
