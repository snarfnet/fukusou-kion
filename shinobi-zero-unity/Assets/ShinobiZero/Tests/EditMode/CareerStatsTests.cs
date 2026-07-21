using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class CareerStatsTests
    {
        [Test] public void WinRecordsOpponentAndCheckout()
        {
            var stats = new CareerStats();
            var tracker = new CareerTracker(stats);
            tracker.BeginMatch(2, 5);
            tracker.RecordPlayerThrow(new DartHit(20, 3), false, false, false, false);
            tracker.RecordPlayerThrow(new DartHit(20, 2), false, true, true, true);
            Assert.That(stats.Wins, Is.EqualTo(1));
            Assert.That(stats.OpponentWins[2], Is.EqualTo(1));
            Assert.That(stats.BestCheckout, Is.EqualTo(100));
        }

        [Test] public void BustDoesNotBecomeBestTurn()
        {
            var stats = new CareerStats();
            var tracker = new CareerTracker(stats);
            tracker.BeginMatch(0, 5);
            tracker.RecordPlayerThrow(new DartHit(20, 3), false, false, false, false);
            tracker.RecordPlayerThrow(new DartHit(20, 3), true, true, false, false);
            Assert.That(stats.BestTurn, Is.Zero);
        }

        [Test] public void HitRateCountsOnlyPlayerThrows()
        {
            var stats = new CareerStats();
            var tracker = new CareerTracker(stats);
            tracker.BeginMatch(0, 5);
            tracker.RecordPlayerThrow(DartHit.Miss, false, false, false, false);
            tracker.RecordPlayerThrow(new DartHit(20, 1), false, true, false, false);
            Assert.That(stats.HitRate, Is.EqualTo(.5f));
        }

        [Test] public void LossCompletesMatch()
        {
            var stats = new CareerStats();
            var tracker = new CareerTracker(stats);
            tracker.BeginMatch(4, 5);
            tracker.RecordEnemyWin();
            Assert.That(stats.Matches, Is.EqualTo(1));
            Assert.That(stats.Losses, Is.EqualTo(1));
        }

        [Test] public void AbortDoesNotChangeCareerTotals()
        {
            var stats = new CareerStats();
            var tracker = new CareerTracker(stats);
            tracker.BeginMatch(1, 5);
            tracker.RecordPlayerThrow(new DartHit(20, 3), false, false, false, false);
            tracker.AbortMatch();
            Assert.That(stats.Matches, Is.Zero);
            Assert.That(stats.Wins, Is.Zero);
            Assert.That(stats.Losses, Is.Zero);
        }

        [Test] public void TurnBoundaryResumeDoesNotDoubleCountCareer()
        {
            var stats = new CareerStats();
            var beforeRestart = new CareerTracker(stats);
            beforeRestart.BeginMatch(2, 5);
            beforeRestart.RecordPlayerThrow(new DartHit(20, 3), false, true, false, false);

            var afterRestart = new CareerTracker(stats);
            afterRestart.BeginMatch(2, 5);
            afterRestart.RecordPlayerThrow(new DartHit(20, 2), false, true, true, true);
            Assert.That(stats.PlayerThrows, Is.EqualTo(2));
            Assert.That(stats.ScoringThrows, Is.EqualTo(2));
            Assert.That(stats.Matches, Is.EqualTo(1));
            Assert.That(stats.Wins, Is.EqualTo(1));
        }

        [Test] public void NormalizeMigratesAndRepairsInvalidValues()
        {
            var stats = new CareerStats
            {
                Version = 1, Revision = -4, Matches = -1, Wins = 3, Losses = 2,
                PlayerThrows = 4, ScoringThrows = 9, Bulls = -2, Triples = 8,
                BestTurn = 999, BestCheckout = 999, OpponentWins = new[] { 2, -3 }
            };
            stats.Normalize(5);
            Assert.That(stats.Version, Is.EqualTo(2));
            Assert.That(stats.Revision, Is.Zero);
            Assert.That(stats.Matches, Is.EqualTo(5));
            Assert.That(stats.ScoringThrows, Is.EqualTo(4));
            Assert.That(stats.Bulls, Is.Zero);
            Assert.That(stats.Triples, Is.EqualTo(4));
            Assert.That(stats.BestTurn, Is.EqualTo(180));
            Assert.That(stats.BestCheckout, Is.EqualTo(170));
            Assert.That(stats.OpponentWins, Has.Length.EqualTo(5));
            Assert.That(stats.OpponentWins[1], Is.Zero);
        }

        [Test] public void HigherRevisionWinsCloudConflict()
        {
            var local = new CareerStats { Revision = 4, Matches = 20 };
            var cloud = new CareerStats { Revision = 5, Matches = 10 };
            Assert.That(CareerSaveResolver.Choose(local, cloud), Is.SameAs(cloud));
        }

        [Test] public void MatchCountBreaksLegacyRevisionTie()
        {
            var local = new CareerStats { Revision = 0, Matches = 4 };
            var cloud = new CareerStats { Revision = 0, Matches = 8 };
            Assert.That(CareerSaveResolver.Choose(local, cloud), Is.SameAs(cloud));
        }

        [Test] public void TimestampBreaksEqualProgressTie()
        {
            var local = new CareerStats { Revision = 2, Matches = 4, UpdatedUtcTicks = 100 };
            var cloud = new CareerStats { Revision = 2, Matches = 4, UpdatedUtcTicks = 200 };
            Assert.That(CareerSaveResolver.Choose(local, cloud), Is.SameAs(cloud));
        }

        [Test] public void LocalWinsExactTie()
        {
            var local = new CareerStats();
            Assert.That(CareerSaveResolver.Choose(local, new CareerStats()), Is.SameAs(local));
        }

        [Test] public void AvailableSaveWinsWhenOtherIsMissing()
        {
            var cloud = new CareerStats { Revision = 3 };
            Assert.That(CareerSaveResolver.Choose(null, cloud), Is.SameAs(cloud));
            Assert.That(CareerSaveResolver.Choose(cloud, null), Is.SameAs(cloud));
        }

        [Test] public void ActiveMatchCannotReplaceNewerCloudCareer()
        {
            var checkpoint = new CareerStats { Revision = 4, Matches = 8, UpdatedUtcTicks = 100 };
            var newerCloud = new CareerStats { Revision = 5, Matches = 9, UpdatedUtcTicks = 200 };
            Assert.That(CareerSaveResolver.CanRestoreCheckpoint(checkpoint, newerCloud), Is.False);
            Assert.That(CareerSaveResolver.CanRestoreCheckpoint(checkpoint, checkpoint), Is.True);
            Assert.That(CareerSaveResolver.CanRestoreCheckpoint(checkpoint, null), Is.True);
        }
    }
}
