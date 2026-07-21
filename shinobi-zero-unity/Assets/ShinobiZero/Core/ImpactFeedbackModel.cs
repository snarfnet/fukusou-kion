namespace ShinobiZero.Core
{
    public enum ImpactTier
    {
        Miss,
        Standard,
        Double,
        Triple,
        Bull,
        Bust,
        Checkout,
        MatchVictory,
        MatchDefeat
    }

    public struct ImpactFeedbackProfile
    {
        public readonly ImpactTier Tier;
        public readonly float CameraStrength;
        public readonly float ZoomDegrees;
        public readonly int SparkCount;
        public readonly float CalloutScale;
        public readonly float CalloutHoldSeconds;

        public ImpactFeedbackProfile(ImpactTier tier, float cameraStrength, float zoomDegrees, int sparkCount, float calloutScale, float calloutHoldSeconds)
        {
            Tier = tier;
            CameraStrength = cameraStrength;
            ZoomDegrees = zoomDegrees;
            SparkCount = sparkCount;
            CalloutScale = calloutScale;
            CalloutHoldSeconds = calloutHoldSeconds;
        }
    }

    public static class ImpactFeedbackModel
    {
        public static ImpactFeedbackProfile Evaluate(ThrowOutcome outcome)
        {
            if (outcome.MatchEnded)
                return outcome.Thrower == Combatant.Player
                    ? new ImpactFeedbackProfile(ImpactTier.MatchVictory, 2.15f, 4.2f, 32, 1.62f, .72f)
                    : new ImpactFeedbackProfile(ImpactTier.MatchDefeat, 1.15f, 1.4f, 12, 1.28f, .62f);
            if (outcome.LegEnded)
                return new ImpactFeedbackProfile(ImpactTier.Checkout, 1.8f, 2.5f, 24, 1.48f, .62f);
            if (outcome.Score.Bust)
                return new ImpactFeedbackProfile(ImpactTier.Bust, .72f, 0f, 5, 1.24f, .48f);
            if (outcome.Hit.Score <= 0)
                return new ImpactFeedbackProfile(ImpactTier.Miss, 0f, 0f, 0, 1f, .28f);
            if (outcome.Hit.Base == 25)
                return new ImpactFeedbackProfile(ImpactTier.Bull, 1.65f, 1.8f, 20, 1.38f, .52f);
            if (outcome.Hit.Multiplier == 3)
                return new ImpactFeedbackProfile(ImpactTier.Triple, 1.42f, 1.1f, 15, 1.3f, .46f);
            if (outcome.Hit.Multiplier == 2)
                return new ImpactFeedbackProfile(ImpactTier.Double, 1.25f, .7f, 12, 1.2f, .4f);
            return new ImpactFeedbackProfile(ImpactTier.Standard, 1f, 0f, 7, 1.08f, .32f);
        }
    }
}
