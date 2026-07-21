using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class OpponentAccuracyModelTests
    {
        [Test] public void BetterSkillProducesTighterSpread() => Assert.That(
            OpponentAccuracyModel.Sigma(.9f, .7f, .7f, false, 3),
            Is.LessThan(OpponentAccuracyModel.Sigma(.3f, .7f, .7f, false, 3)));

        [Test] public void ComposureReducesCheckoutPressure() => Assert.That(
            OpponentAccuracyModel.Sigma(.7f, .7f, .95f, true, 3),
            Is.LessThan(OpponentAccuracyModel.Sigma(.7f, .7f, .1f, true, 3)));

        [Test] public void InconsistentFighterFadesAcrossTurn() => Assert.That(
            OpponentAccuracyModel.Sigma(.6f, .1f, .5f, false, 1),
            Is.GreaterThan(OpponentAccuracyModel.Sigma(.6f, .1f, .5f, false, 3)));

        [Test] public void SamplingIsDeterministicForGivenInputs()
        {
            var a = OpponentAccuracyModel.Sample(.1f, .02f, .5f, .25f);
            var b = OpponentAccuracyModel.Sample(.1f, .02f, .5f, .25f);
            Assert.That(a.X, Is.EqualTo(b.X));
            Assert.That(a.Y, Is.EqualTo(b.Y));
        }
    }
}
