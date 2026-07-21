namespace ShinobiZero.Core
{
    public enum NinjaReactionType { None, Approval, Frustration, Victory, Defeat }

    public struct NinjaReactionPose
    {
        public readonly NinjaReactionType Type;
        public readonly float Duration;
        public readonly float TorsoPitch;
        public readonly float HeadYaw;
        public readonly float VerticalShift;

        public NinjaReactionPose(NinjaReactionType type, float duration, float torsoPitch, float headYaw, float verticalShift)
        {
            Type = type;
            Duration = duration;
            TorsoPitch = torsoPitch;
            HeadYaw = headYaw;
            VerticalShift = verticalShift;
        }
    }

    public static class NinjaReactionModel
    {
        public static NinjaReactionPose Evaluate(ThrowOutcome outcome)
        {
            if (outcome.MatchEnded)
                return outcome.Thrower == Combatant.Enemy
                    ? new NinjaReactionPose(NinjaReactionType.Victory, .9f, -12f, 8f, .1f)
                    : new NinjaReactionPose(NinjaReactionType.Defeat, .95f, 18f, -10f, -.14f);
            if (outcome.LegEnded)
                return outcome.Thrower == Combatant.Enemy
                    ? new NinjaReactionPose(NinjaReactionType.Approval, .42f, -7f, 4f, .035f)
                    : new NinjaReactionPose(NinjaReactionType.Frustration, .4f, 8f, -6f, -.025f);
            if (outcome.Score.Bust)
                return outcome.Thrower == Combatant.Enemy
                    ? new NinjaReactionPose(NinjaReactionType.Frustration, .38f, 9f, -7f, -.025f)
                    : new NinjaReactionPose(NinjaReactionType.Approval, .3f, -4f, 3f, .02f);
            if (outcome.Hit.Base == 25 || outcome.Hit.Multiplier == 3)
                return outcome.Thrower == Combatant.Enemy
                    ? new NinjaReactionPose(NinjaReactionType.Approval, .3f, -4f, 3f, .02f)
                    : new NinjaReactionPose(NinjaReactionType.Frustration, .28f, 5f, -4f, -.015f);
            return new NinjaReactionPose(NinjaReactionType.None, 0f, 0f, 0f, 0f);
        }
    }
}
