using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class OpponentDifficultyModelTests
    {
        [TestCase(.34f, 1)]
        [TestCase(.48f, 2)]
        [TestCase(.62f, 3)]
        [TestCase(.77f, 4)]
        [TestCase(.91f, 5)]
        [TestCase(-1f, 1)]
        [TestCase(2f, 5)]
        public void SkillMapsToReadableDifficulty(float skill, int expected) =>
            Assert.That(OpponentDifficultyModel.Level(skill), Is.EqualTo(expected));

        [Test] public void StarsAlwaysUseFiveSymbols()
        {
            Assert.That(OpponentDifficultyModel.Stars(.62f), Is.EqualTo("★★★☆☆"));
        }
    }
}
