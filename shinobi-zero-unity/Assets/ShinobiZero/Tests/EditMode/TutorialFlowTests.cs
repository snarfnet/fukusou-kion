using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class TutorialFlowTests
    {
        [Test] public void StartsOnThrowingPage()
        {
            var flow = new TutorialFlow();
            Assert.That(flow.Page, Is.EqualTo(TutorialPage.Throwing));
            Assert.That(flow.PageNumber, Is.EqualTo(1));
        }

        [Test] public void ThreeAdvancesCompleteTutorial()
        {
            var flow = new TutorialFlow();
            flow.Next(); flow.Next(); flow.Next();
            Assert.That(flow.IsComplete, Is.True);
        }

        [Test] public void SkipCompletesImmediately()
        {
            var flow = new TutorialFlow();
            flow.Skip();
            Assert.That(flow.IsComplete, Is.True);
        }

        [Test] public void RestartReturnsToFirstPage()
        {
            var flow = new TutorialFlow();
            flow.Skip(); flow.Restart();
            Assert.That(flow.Page, Is.EqualTo(TutorialPage.Throwing));
        }
    }
}
