using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class CheckoutAdvisorTests
    {
        [TestCase(40, 1, "D20")]
        [TestCase(32, 1, "D16")]
        [TestCase(50, 1, "BULL")]
        [TestCase(100, 2, "T20 → D20")]
        [TestCase(170, 3, "T20 → T20 → BULL")]
        public void FindsConventionalDoubleOuts(int remaining, int darts, string expected)
        {
            var route = CheckoutAdvisor.Find(remaining, darts, true);
            Assert.That(CheckoutAdvisor.Format(route), Is.EqualTo(expected));
        }

        [Test] public void OneSixtyNineIsNotAThreeDartCheckout() => Assert.That(
            CheckoutAdvisor.Find(169, 3, true).IsPossible, Is.False);

        [Test] public void StraightOutAllowsTripleTwenty() => Assert.That(
            CheckoutAdvisor.Format(CheckoutAdvisor.Find(60, 1, false)), Is.EqualTo("T20"));

        [Test] public void RemainingOneCannotFinish() => Assert.That(
            CheckoutAdvisor.Find(1, 3, true).IsPossible, Is.False);
    }
}
