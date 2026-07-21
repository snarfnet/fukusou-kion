using System.Collections.Generic;
using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class CheckoutExhaustiveTests
    {
        [Test] public void OnlyOfficialBogeyNumbersFailBetweenTwoAndOneSeventy()
        {
            var missing = new List<int>();
            for (var score = 2; score <= 170; score++)
                if (!CheckoutAdvisor.Find(score, 3, true).IsPossible) missing.Add(score);
            Assert.That(missing, Is.EqualTo(new[] { 159, 162, 163, 165, 166, 168, 169 }));
        }

        [Test] public void EverySuggestedRouteScoresExactlyAndEndsOnDouble()
        {
            for (var score = 2; score <= 170; score++)
            {
                var route = CheckoutAdvisor.Find(score, 3, true);
                if (!route.IsPossible) continue;
                var remaining = score;
                for (var i = 0; i < route.Hits.Length; i++)
                {
                    remaining -= route.Hits[i].Score;
                    if (i < route.Hits.Length - 1) Assert.That(remaining, Is.GreaterThan(1), "Premature bust at " + score);
                }
                Assert.That(remaining, Is.Zero, "Route total at " + score);
                Assert.That(route.Hits[route.Hits.Length - 1].IsDouble, Is.True, "Final dart at " + score);
            }
        }

        [Test] public void OneDartCheckoutsAreDoublesAndBullOnly()
        {
            for (var score = 2; score <= 50; score++)
            {
                var possible = CheckoutAdvisor.Find(score, 1, true).IsPossible;
                var expected = (score <= 40 && score % 2 == 0) || score == 50;
                Assert.That(possible, Is.EqualTo(expected), "One dart checkout at " + score);
            }
        }

        [Test] public void AboveMaximumCannotFinishInThreeDarts()
        {
            for (var score = 171; score <= 200; score++)
                Assert.That(CheckoutAdvisor.Find(score, 3, true).IsPossible, Is.False, "Score " + score);
        }
    }
}
