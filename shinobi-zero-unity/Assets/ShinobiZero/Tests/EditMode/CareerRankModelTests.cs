using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class CareerRankModelTests
    {
        [TestCase(0, 0, CareerRank.Initiate)]
        [TestCase(1, 1, CareerRank.Genin)]
        [TestCase(3, 2, CareerRank.Chunin)]
        [TestCase(7, 4, CareerRank.Jonin)]
        [TestCase(10, 5, CareerRank.Shadow)]
        public void ExactThresholdAwardsRank(int wins, int defeated, CareerRank expected) =>
            Assert.That(CareerRankModel.Evaluate(Stats(wins, defeated)).Rank, Is.EqualTo(expected));

        [Test] public void WinsAloneCannotSkipOpponentMastery()
        {
            Assert.That(CareerRankModel.Evaluate(Stats(20, 1)).Rank, Is.EqualTo(CareerRank.Genin));
        }

        [Test] public void OpponentsAloneCannotSkipWinMastery()
        {
            Assert.That(CareerRankModel.Evaluate(Stats(2, 5)).Rank, Is.EqualTo(CareerRank.Genin));
        }

        [Test] public void ShadowIsMaximum()
        {
            var progress = CareerRankModel.Evaluate(Stats(10, 5));
            Assert.That(progress.IsMaximum, Is.True);
            Assert.That(CareerRankModel.Japanese(progress.Rank), Is.EqualTo("影"));
            Assert.That(CareerRankModel.English(progress.Rank), Is.EqualTo("SHADOW"));
        }

        [Test] public void NextRankRequirementsAreExposed()
        {
            var progress = CareerRankModel.Evaluate(Stats(3, 2));
            Assert.That(progress.NextWins, Is.EqualTo(7));
            Assert.That(progress.NextOpponents, Is.EqualTo(4));
        }

        [TestCase(CareerRank.Initiate, CareerRank.Genin, true)]
        [TestCase(CareerRank.Chunin, CareerRank.Chunin, false)]
        [TestCase(CareerRank.Jonin, CareerRank.Genin, false)]
        public void PromotionRequiresStrictlyHigherRank(CareerRank previous, CareerRank current, bool expected) =>
            Assert.That(CareerRankModel.IsPromotion(previous, current), Is.EqualTo(expected));

        private static CareerStats Stats(int wins, int defeated)
        {
            var opponentWins = new int[5];
            for (var i = 0; i < defeated && i < opponentWins.Length; i++) opponentWins[i] = 1;
            return new CareerStats { Wins = wins, OpponentWins = opponentWins };
        }
    }
}
