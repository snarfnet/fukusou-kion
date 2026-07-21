using System;

namespace ShinobiZero.Core
{
    public enum TutorialPage { Throwing, Scoring, Checkout, Complete }

    public sealed class TutorialFlow
    {
        public TutorialPage Page { get; private set; }
        public int PageNumber { get { return Page == TutorialPage.Complete ? 3 : (int)Page + 1; } }
        public bool IsComplete { get { return Page == TutorialPage.Complete; } }

        public TutorialFlow() { Page = TutorialPage.Throwing; }

        public TutorialPage Next()
        {
            if (Page < TutorialPage.Complete) Page++;
            return Page;
        }

        public void Skip() { Page = TutorialPage.Complete; }

        public void Restart() { Page = TutorialPage.Throwing; }
    }
}
