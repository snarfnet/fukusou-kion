using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class OpponentBrainTests
    {
        private readonly OpponentBrain _brain = new OpponentBrain();

        [Test] public void AimsDoubleTwentyForForty() => AssertAim(40, true, 20, 2);
        [Test] public void AimsBullForFifty() => AssertAim(50, true, 25, 2);
        [Test] public void SkilledEnemyPrefersTriples() => Assert.That(
            _brain.Choose(301, false, .8f, 20).Multiplier, Is.EqualTo(3));
        [Test] public void NovicePrefersSingles() => Assert.That(
            _brain.Choose(301, false, .3f, 19).Multiplier, Is.EqualTo(1));
        [Test] public void AggressiveFighterChoosesTripleAtEqualSkill() => Assert.That(
            _brain.Choose(301, false, .5f, 20, .8f).Multiplier, Is.EqualTo(3));
        [Test] public void CautiousFighterChoosesSingleAtEqualSkill() => Assert.That(
            _brain.Choose(301, false, .5f, 20, .2f).Multiplier, Is.EqualTo(1));

        [Test]
        public void NoviceNeverAimsToBustOnOddDoubleOutRemainder()
        {
            for (var remaining = 3; remaining < 40; remaining += 2)
            {
                var aim = _brain.Choose(remaining, true, .2f, 20);
                var leave = remaining - aim.Base * aim.Multiplier;
                Assert.That(aim.Multiplier, Is.EqualTo(1), "remaining " + remaining);
                Assert.That(leave, Is.GreaterThan(0), "remaining " + remaining);
                Assert.That(leave % 2, Is.EqualTo(0), "remaining " + remaining);
            }
            Assert.That(_brain.Choose(39, true, .2f, 20).Base, Is.EqualTo(7));
            Assert.That(_brain.Choose(31, true, .2f, 20).Base, Is.EqualTo(1));
        }

        [Test] public void StrategyChangesRiskAtEqualSkill()
        {
            var safe = _brain.Choose(301, false, .5f, 20, .5f, 3, OpponentStrategy.Conservative);
            var attack = _brain.Choose(301, false, .5f, 20, .5f, 3, OpponentStrategy.Aggressive);
            Assert.That(safe.Multiplier, Is.EqualTo(1));
            Assert.That(attack.Multiplier, Is.EqualTo(3));
        }

        [Test] public void CheckoutSpecialistSeesRouteBeforeRhythmFighter()
        {
            var specialist = _brain.Choose(104, true, .55f, 20, .5f, 3, OpponentStrategy.CheckoutSpecialist);
            var rhythm = _brain.Choose(104, true, .55f, 20, .5f, 3, OpponentStrategy.Rhythm);
            Assert.That(specialist.Base, Is.EqualTo(18));
            Assert.That(specialist.Multiplier, Is.EqualTo(3));
            Assert.That(rhythm.Base, Is.EqualTo(20));
        }

        [Test] public void FiveOpponentsUseFiveDistinctStrategies()
        {
            var seen = new System.Collections.Generic.HashSet<OpponentStrategy>();
            for (var i = 0; i < OpponentTuningCatalog.Count; i++) seen.Add(OpponentTuningCatalog.Get(i).Strategy);
            Assert.That(seen.Count, Is.EqualTo(5));
        }

        [Test] public void EveryStrategyHasPlayerFacingName()
        {
            for (var i = 0; i < OpponentTuningCatalog.Count; i++)
                Assert.That(OpponentStrategyNames.Japanese(OpponentTuningCatalog.Get(i).Strategy), Is.Not.Empty);
        }

        private void AssertAim(int remaining, bool doubleOut, int baseValue, int multiplier)
        {
            var aim = _brain.Choose(remaining, doubleOut, .8f, 20);
            Assert.That(aim.Base, Is.EqualTo(baseValue));
            Assert.That(aim.Multiplier, Is.EqualTo(multiplier));
        }
    }
}
