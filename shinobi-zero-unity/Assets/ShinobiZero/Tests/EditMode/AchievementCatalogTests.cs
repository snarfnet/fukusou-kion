using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class AchievementCatalogTests
    {
        [Test] public void EmptyCareerUnlocksNothing() => Assert.That(
            AchievementCatalog.Evaluate(new CareerStats()), Is.Empty);

        [Test] public void FirstWinUnlocksFirstVictory()
        {
            var stats = new CareerStats { Wins = 1 };
            Assert.That(AchievementCatalog.Evaluate(stats), Does.Contain(AchievementCatalog.FirstVictory));
        }

        [Test] public void CheckoutAndMaximumUseExactThresholds()
        {
            var stats = new CareerStats { BestCheckout = 100, BestTurn = 180 };
            var unlocked = AchievementCatalog.Evaluate(stats);
            Assert.That(unlocked, Does.Contain(AchievementCatalog.CenturyCheckout));
            Assert.That(unlocked, Does.Contain(AchievementCatalog.MaximumTurn));
        }

        [Test] public void FiveShadowsRequiresEveryOpponent()
        {
            var stats = new CareerStats { OpponentWins = new[] { 1, 1, 1, 1, 0 } };
            Assert.That(AchievementCatalog.Evaluate(stats), Does.Not.Contain(AchievementCatalog.FiveShadows));
            stats.OpponentWins[4] = 1;
            Assert.That(AchievementCatalog.Evaluate(stats), Does.Contain(AchievementCatalog.FiveShadows));
        }

        [Test] public void IdsAreStableForPlatformBackends() => Assert.That(
            AchievementCatalog.TenVictories, Is.EqualTo("SZ_TEN_VICTORIES"));
    }
}
