using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class ImpactFeedbackModelTests
    {
        [TestCase(20, 1, ImpactTier.Standard)]
        [TestCase(20, 2, ImpactTier.Double)]
        [TestCase(20, 3, ImpactTier.Triple)]
        [TestCase(25, 1, ImpactTier.Bull)]
        [TestCase(25, 2, ImpactTier.Bull)]
        public void ScoringRingSelectsImpactTier(int baseValue, int multiplier, ImpactTier expected)
        {
            var outcome = Outcome(new DartHit(baseValue, multiplier));
            Assert.That(ImpactFeedbackModel.Evaluate(outcome).Tier, Is.EqualTo(expected));
        }

        [Test] public void BustOverridesPremiumRing()
        {
            var outcome = new ThrowOutcome(Combatant.Player, new DartHit(20, 3), new ScoreResolution(20, true, false, false), true, false, false);
            Assert.That(ImpactFeedbackModel.Evaluate(outcome).Tier, Is.EqualTo(ImpactTier.Bust));
        }

        [Test] public void PlayerMatchWinGetsStrongestFinish()
        {
            var outcome = new ThrowOutcome(Combatant.Player, new DartHit(20, 2), new ScoreResolution(0, false, false, true), true, true, true);
            var profile = ImpactFeedbackModel.Evaluate(outcome);
            Assert.That(profile.Tier, Is.EqualTo(ImpactTier.MatchVictory));
            Assert.That(profile.CameraStrength, Is.GreaterThan(ImpactFeedbackModel.Evaluate(Outcome(DartHit.Bull)).CameraStrength));
            Assert.That(profile.SparkCount, Is.GreaterThan(20));
            Assert.That(profile.CalloutScale, Is.GreaterThan(ImpactFeedbackModel.Evaluate(Outcome(DartHit.Bull)).CalloutScale));
            Assert.That(profile.CalloutHoldSeconds, Is.GreaterThan(.5f));
        }

        [Test] public void EnemyMatchWinUsesDefeatTone()
        {
            var outcome = new ThrowOutcome(Combatant.Enemy, new DartHit(20, 2), new ScoreResolution(0, false, false, true), true, true, true);
            Assert.That(ImpactFeedbackModel.Evaluate(outcome).Tier, Is.EqualTo(ImpactTier.MatchDefeat));
        }

        private static ThrowOutcome Outcome(DartHit hit) =>
            new ThrowOutcome(Combatant.Player, hit, new ScoreResolution(301 - hit.Score, false, false, false), false, false, false);
    }
}
