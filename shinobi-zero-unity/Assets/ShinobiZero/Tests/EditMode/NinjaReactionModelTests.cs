using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class NinjaReactionModelTests
    {
        [Test] public void EnemyVictoryGetsVictoryStance() => AssertReaction(Combatant.Enemy, new DartHit(20, 2), false, true, NinjaReactionType.Victory);
        [Test] public void PlayerVictoryDefeatsNinja() => AssertReaction(Combatant.Player, new DartHit(20, 2), false, true, NinjaReactionType.Defeat);
        [Test] public void EnemyBustShowsFrustration() => AssertReaction(Combatant.Enemy, new DartHit(20, 3), true, false, NinjaReactionType.Frustration);
        [Test] public void PlayerBustGetsSubtleApproval() => AssertReaction(Combatant.Player, new DartHit(20, 3), true, false, NinjaReactionType.Approval);
        [Test] public void EnemyBullGetsApproval() => AssertReaction(Combatant.Enemy, DartHit.Bull, false, false, NinjaReactionType.Approval);
        [Test] public void PlayerTripleChallengesNinja() => AssertReaction(Combatant.Player, new DartHit(20, 3), false, false, NinjaReactionType.Frustration);
        [Test] public void OrdinarySingleGetsNoReaction() => AssertReaction(Combatant.Player, new DartHit(20, 1), false, false, NinjaReactionType.None);

        private static void AssertReaction(Combatant thrower, DartHit hit, bool bust, bool matchEnded, NinjaReactionType expected)
        {
            var outcome = new ThrowOutcome(thrower, hit, new ScoreResolution(matchEnded ? 0 : 100, bust, false, matchEnded), bust || matchEnded, matchEnded, matchEnded);
            Assert.That(NinjaReactionModel.Evaluate(outcome).Type, Is.EqualTo(expected));
        }
    }
}
