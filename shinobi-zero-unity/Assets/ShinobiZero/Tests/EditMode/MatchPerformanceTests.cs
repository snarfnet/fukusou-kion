using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class MatchPerformanceTests
    {
        [Test] public void ThreeDartAverageUsesCountedScore()
        {
            var tracker = new MatchPerformanceTracker();
            tracker.Record(new DartHit(20, 3), false, false, false);
            tracker.Record(new DartHit(20, 3), false, false, false);
            tracker.Record(new DartHit(20, 3), false, true, false);
            Assert.That(tracker.Performance.ThreeDartAverage, Is.EqualTo(180f));
            Assert.That(tracker.Performance.BestTurn, Is.EqualTo(180));
        }


        [Test] public void SnapshotRestoresSettledAndCurrentTurnTotals()
        {
            var source = new MatchPerformanceTracker();
            source.Record(new DartHit(20, 3), false, false, false);
            var restored = new MatchPerformanceTracker();
            Assert.That(restored.TryRestore(source.Capture()), Is.True);
            restored.Record(new DartHit(20, 1), false, true, false);
            Assert.That(restored.Performance.Throws, Is.EqualTo(2));
            Assert.That(restored.Performance.CountedScore, Is.EqualTo(80));
            Assert.That(restored.Performance.BestTurn, Is.EqualTo(80));
        }

        [Test] public void InvalidPerformanceSnapshotIsRejected()
        {
            var tracker = new MatchPerformanceTracker();
            Assert.That(tracker.TryRestore(new MatchPerformanceSnapshot { Throws = 1, ScoringHits = 2 }), Is.False);
        }

        [Test] public void BustTurnAddsNoCountedScore()
        {
            var tracker = new MatchPerformanceTracker();
            tracker.Record(new DartHit(20, 3), false, false, false);
            tracker.Record(new DartHit(20, 3), true, true, false);
            Assert.That(tracker.Performance.CountedScore, Is.Zero);
            Assert.That(tracker.Performance.Throws, Is.EqualTo(2));
        }

        [Test] public void PhysicalHitsStillCountDuringBust()
        {
            var tracker = new MatchPerformanceTracker();
            tracker.Record(new DartHit(20, 3), false, false, false);
            tracker.Record(new DartHit(20, 3), true, true, false);
            Assert.That(tracker.Performance.HitRate, Is.EqualTo(1f));
        }

        [Test] public void LegWinningTurnBecomesCheckout()
        {
            var tracker = new MatchPerformanceTracker();
            tracker.Record(new DartHit(20, 3), false, false, false);
            tracker.Record(new DartHit(20, 2), false, true, true);
            Assert.That(tracker.Performance.BestCheckout, Is.EqualTo(100));
        }

        [Test] public void ResetStartsFreshPerformance()
        {
            var tracker = new MatchPerformanceTracker();
            tracker.Record(new DartHit(20, 1), false, true, false);
            tracker.Reset();
            Assert.That(tracker.Performance.Throws, Is.Zero);
        }
    }
}
