using System;
using System.Linq;
using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class PlatformProgressTests
    {
        [Test] public void SnapshotPublishesStableCompleteStats()
        {
            var career = new CareerStats
            {
                Matches = 12, Wins = 7, Losses = 5, LegsWon = 9,
                PlayerThrows = 180, Bulls = 4, Triples = 28,
                BestTurn = 140, BestCheckout = 104
            };
            var snapshot = PlatformProgressSnapshot.From(career);

            Assert.That(snapshot.Stats.Length, Is.EqualTo(9));
            Assert.That(snapshot.Stats.Single(stat => stat.Id == PlatformProgressSnapshot.Wins).Value, Is.EqualTo(7));
            Assert.That(snapshot.Stats.Single(stat => stat.Id == PlatformProgressSnapshot.BestCheckout).Value, Is.EqualTo(104));
            Assert.That(snapshot.Achievements, Does.Contain(AchievementCatalog.FirstVictory));
            Assert.That(snapshot.Achievements, Does.Contain(AchievementCatalog.CenturyCheckout));
        }

        [Test] public void PlatformIdsAreNamespacedAndUnique()
        {
            var snapshot = PlatformProgressSnapshot.From(new CareerStats());
            Assert.That(snapshot.Stats.Select(stat => stat.Id).Distinct().Count(), Is.EqualTo(snapshot.Stats.Length));
            Assert.That(snapshot.Stats.All(stat => stat.Id.StartsWith("SZ_STAT_", StringComparison.Ordinal)), Is.True);
        }

        [Test] public void NullCareerIsRejected() =>
            Assert.Throws<ArgumentNullException>(() => PlatformProgressSnapshot.From(null));
    }
}
