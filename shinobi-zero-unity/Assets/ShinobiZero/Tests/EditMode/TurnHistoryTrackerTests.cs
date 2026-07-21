using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class TurnHistoryTrackerTests
    {
        [Test] public void AccumulatesThreeThrows()
        {
            var tracker = new TurnHistoryTracker();
            tracker.Record(Outcome(Combatant.Player, new DartHit(20, 3)));
            tracker.Record(Outcome(Combatant.Player, new DartHit(20, 1)));
            tracker.Record(Outcome(Combatant.Player, DartHit.Miss, true));
            Assert.That(tracker.Count, Is.EqualTo(3));
            Assert.That(tracker.Total, Is.EqualTo(80));
        }

        [Test] public void NewThrowerStartsFreshSummary()
        {
            var tracker = new TurnHistoryTracker();
            tracker.Record(Outcome(Combatant.Player, new DartHit(20, 1), true));
            tracker.Record(Outcome(Combatant.Enemy, new DartHit(19, 3)));
            Assert.That(tracker.Count, Is.EqualTo(1));
            Assert.That(tracker.Total, Is.EqualTo(57));
            Assert.That(tracker.Thrower, Is.EqualTo(Combatant.Enemy));
        }

        [Test] public void BustShowsZeroCountedTotal()
        {
            var tracker = new TurnHistoryTracker();
            tracker.Record(Outcome(Combatant.Player, new DartHit(20, 3)));
            tracker.Record(new ThrowOutcome(Combatant.Player, new DartHit(20, 3), new ScoreResolution(100, true, false, false), true, false, false));
            Assert.That(tracker.Bust, Is.True);
            Assert.That(tracker.Total, Is.Zero);
            Assert.That(tracker.Count, Is.EqualTo(2));
        }

        [Test] public void LegBoundaryResetsEvenWhenSamePlayerStartsNext()
        {
            var tracker = new TurnHistoryTracker();
            tracker.Record(new ThrowOutcome(Combatant.Player, new DartHit(20, 2), new ScoreResolution(0, false, false, true), true, true, false));
            tracker.Record(Outcome(Combatant.Player, new DartHit(20, 1)));
            Assert.That(tracker.Count, Is.EqualTo(1));
            Assert.That(tracker.Total, Is.EqualTo(20));
        }

        [Test] public void ResetClearsAllState()
        {
            var tracker = new TurnHistoryTracker();
            tracker.Record(Outcome(Combatant.Enemy, new DartHit(25, 2)));
            tracker.Reset();
            Assert.That(tracker.Count, Is.Zero);
            Assert.That(tracker.Total, Is.Zero);
            Assert.That(tracker.Thrower, Is.Null);
        }

        private static ThrowOutcome Outcome(Combatant thrower, DartHit hit, bool turnEnded = false) =>
            new ThrowOutcome(thrower, hit, new ScoreResolution(301 - hit.Score, false, false, false), turnEnded, false, false);
    }
}
