using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class MatchEngineTests
    {
        [Test]
        public void ThrowBeforeMatchStartIsRejected()
        {
            var match = new MatchEngine();
            Assert.Throws<System.InvalidOperationException>(() => match.Submit(DartHit.Miss));
        }

        [Test]
        public void ThreePlayerThrowsPassTurnToEnemy()
        {
            var match = new MatchEngine();
            match.Start(new MatchConfig(301, false));
            match.Submit(DartHit.Miss);
            match.Submit(DartHit.Miss);
            var third = match.Submit(DartHit.Miss);
            Assert.That(third.TurnEnded, Is.True);
            Assert.That(match.Turn, Is.EqualTo(Combatant.Enemy));
            Assert.That(match.DartsLeft, Is.EqualTo(3));
        }

        [Test]
        public void EnemyTurnCompletionAdvancesRound()
        {
            var match = new MatchEngine();
            match.Start(new MatchConfig(301, false));
            for (var i = 0; i < 6; i++) match.Submit(DartHit.Miss);
            Assert.That(match.Round, Is.EqualTo(2));
            Assert.That(match.Turn, Is.EqualTo(Combatant.Player));
        }

        [Test]
        public void EnemyStarterDoesNotAdvanceRoundUntilPlayerCompletesTurn()
        {
            var match = new MatchEngine();
            match.Start(new MatchConfig(301, false, 1, Combatant.Enemy));
            SubmitMissTurn(match);
            Assert.That(match.Round, Is.EqualTo(1));
            Assert.That(match.Turn, Is.EqualTo(Combatant.Player));
            SubmitMissTurn(match);
            Assert.That(match.Round, Is.EqualTo(2));
            Assert.That(match.Turn, Is.EqualTo(Combatant.Enemy));
        }

        [Test]
        public void SecondLegRoundUsesAlternatedStarter()
        {
            var match = new MatchEngine();
            match.Start(new MatchConfig(301, false, 2, Combatant.Player));
            WinLeg(match, Combatant.Player);
            Assert.That(match.Turn, Is.EqualTo(Combatant.Enemy));
            SubmitMissTurn(match);
            Assert.That(match.Round, Is.EqualTo(1));
            SubmitMissTurn(match);
            Assert.That(match.Round, Is.EqualTo(2));
        }

        [Test]
        public void BustEndsTurnImmediatelyAndRestoresScore()
        {
            var match = new MatchEngine();
            match.Start(new MatchConfig(301, false));
            for (var i = 0; i < 3; i++) match.Submit(new DartHit(20, 3));
            for (var i = 0; i < 3; i++) match.Submit(DartHit.Miss);
            match.Submit(new DartHit(20, 3));
            var bust = match.Submit(new DartHit(20, 3));
            Assert.That(bust.Score.Bust, Is.True);
            Assert.That(match.Turn, Is.EqualTo(Combatant.Enemy));
            Assert.That(match.PlayerScore, Is.EqualTo(121));
        }

        [Test]
        public void BestOfThreeRequiresTwoLegsAndAlternatesStarter()
        {
            var match = new MatchEngine();
            match.Start(new MatchConfig(301, false, 2));
            var firstLeg = WinLeg(match, Combatant.Player);
            Assert.That(firstLeg.LegEnded, Is.True);
            Assert.That(firstLeg.MatchEnded, Is.False);
            Assert.That(match.PlayerLegs, Is.EqualTo(1));
            Assert.That(match.Turn, Is.EqualTo(Combatant.Enemy));

            WinLeg(match, Combatant.Enemy);
            Assert.That(match.EnemyLegs, Is.EqualTo(1));
            Assert.That(match.Turn, Is.EqualTo(Combatant.Player));

            var decider = WinLeg(match, Combatant.Player);
            Assert.That(decider.MatchEnded, Is.True);
            Assert.That(match.Winner, Is.EqualTo(Combatant.Player));
            Assert.That(match.LegNumber, Is.EqualTo(3));
        }

        [Test] public void EnemyCanStartMatch()
        {
            var match = new MatchEngine();
            match.Start(new MatchConfig(301, false, 1, Combatant.Enemy));
            Assert.That(match.Turn, Is.EqualTo(Combatant.Enemy));
            Assert.That(match.Config.StartingPlayer, Is.EqualTo(Combatant.Enemy));
        }

        [Test] public void EnemyStartedSeriesAlternatesEveryLeg()
        {
            var match = new MatchEngine();
            match.Start(new MatchConfig(301, false, 2, Combatant.Enemy));
            WinLeg(match, Combatant.Enemy);
            Assert.That(match.Turn, Is.EqualTo(Combatant.Player));
            WinLeg(match, Combatant.Player);
            Assert.That(match.Turn, Is.EqualTo(Combatant.Enemy));
        }

        [Test] public void MatchOrderAlternatesBothDirections()
        {
            Assert.That(MatchOrder.Opponent(Combatant.Player), Is.EqualTo(Combatant.Enemy));
            Assert.That(MatchOrder.Opponent(Combatant.Enemy), Is.EqualTo(Combatant.Player));
        }

        private static ThrowOutcome WinLeg(MatchEngine match, Combatant thrower)
        {
            Assert.That(match.Turn, Is.EqualTo(thrower));
            match.Submit(new DartHit(20, 3));
            match.Submit(new DartHit(20, 3));
            match.Submit(new DartHit(20, 3));
            Assert.That(match.Turn, Is.Not.EqualTo(thrower));
            match.Submit(DartHit.Miss);
            match.Submit(DartHit.Miss);
            match.Submit(DartHit.Miss);
            Assert.That(match.Turn, Is.EqualTo(thrower));
            match.Submit(new DartHit(20, 3));
            match.Submit(new DartHit(20, 3));
            return match.Submit(new DartHit(1, 1));
        }

        private static void SubmitMissTurn(MatchEngine match)
        {
            match.Submit(DartHit.Miss);
            match.Submit(DartHit.Miss);
            match.Submit(DartHit.Miss);
        }

        [Test]
        public void AbortEndsActiveMatchWithoutWinner()
        {
            var match = new MatchEngine();
            match.Start(new MatchConfig(301, true));
            Assert.That(match.Abort(), Is.True);
            Assert.That(match.IsFinished, Is.True);
            Assert.That(match.Winner, Is.Null);
            Assert.That(match.Abort(), Is.False);
            Assert.Throws<System.InvalidOperationException>(() => match.Submit(DartHit.Miss));
        }

        [Test]
        public void ActiveMatchRoundTripsWithoutChangingNextResolution()
        {
            var original = new MatchEngine();
            original.Start(new MatchConfig(501, true, 2, Combatant.Enemy));
            original.Submit(new DartHit(20, 3));
            var restored = new MatchEngine();
            Assert.That(restored.TryRestore(original.Capture()), Is.True);
            Assert.That(restored.Config.StartingPlayer, Is.EqualTo(Combatant.Enemy));
            Assert.That(restored.EnemyScore, Is.EqualTo(441));
            Assert.That(restored.DartsLeft, Is.EqualTo(2));
            var expected = original.Submit(new DartHit(19, 3));
            var actual = restored.Submit(new DartHit(19, 3));
            Assert.That(actual.Score.Remaining, Is.EqualTo(expected.Score.Remaining));
            Assert.That(restored.DartsLeft, Is.EqualTo(original.DartsLeft));
        }

        [Test]
        public void CorruptMatchSnapshotIsRejectedWithoutMutation()
        {
            var match = new MatchEngine();
            var corrupt = new MatchStateSnapshot { StartScore = 301, LegsToWin = 1, PlayerScore = -4, EnemyScore = 301, DartsLeft = 3, Round = 1 };
            Assert.That(match.TryRestore(corrupt), Is.False);
            Assert.That(match.HasStarted, Is.False);
        }
    }
}
