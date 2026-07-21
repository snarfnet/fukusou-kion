using System;

namespace ShinobiZero.Core
{
    public enum OpponentStrategy
    {
        Conservative,
        Rhythm,
        Aggressive,
        CheckoutSpecialist,
        Adaptive
    }

    public static class OpponentStrategyNames
    {
        public static string Japanese(OpponentStrategy strategy)
        {
            if (strategy == OpponentStrategy.Conservative) return "堅実型";
            if (strategy == OpponentStrategy.Rhythm) return "連投型";
            if (strategy == OpponentStrategy.Aggressive) return "強襲型";
            if (strategy == OpponentStrategy.CheckoutSpecialist) return "詰将棋型";
            return "無形型";
        }

        public static string English(OpponentStrategy strategy)
        {
            if (strategy == OpponentStrategy.Conservative) return "Steady";
            if (strategy == OpponentStrategy.Rhythm) return "Rhythm";
            if (strategy == OpponentStrategy.Aggressive) return "Assault";
            if (strategy == OpponentStrategy.CheckoutSpecialist) return "Tactician";
            return "Adaptive";
        }
    }

    public struct AimTarget
    {
        public readonly int Base;
        public readonly int Multiplier;
        public readonly float Precision;

        public AimTarget(int baseValue, int multiplier, float precision)
        {
            Base = baseValue;
            Multiplier = multiplier;
            Precision = precision;
        }
    }

    public sealed class OpponentBrain
    {
        public AimTarget Choose(int remaining, bool doubleOut, float skill, int preferredBase, float aggression = .5f,
            int dartsAvailable = 3, OpponentStrategy strategy = OpponentStrategy.Rhythm)
        {
            skill = Math.Max(0f, Math.Min(1f, skill));
            var checkoutThreshold = strategy == OpponentStrategy.Adaptive ? .42f
                : strategy == OpponentStrategy.CheckoutSpecialist ? .5f : .65f;
            if (skill >= checkoutThreshold)
            {
                var route = CheckoutAdvisor.Find(remaining, dartsAvailable, doubleOut);
                if (route.IsPossible)
                {
                    var first = route.Hits[0];
                    return new AimTarget(first.Base, first.Multiplier, skill);
                }
            }
            if (doubleOut)
            {
                if (remaining == 50) return new AimTarget(25, 2, skill);
                if (remaining <= 40 && remaining > 1 && remaining % 2 == 0)
                    return new AimTarget(remaining / 2, 2, skill);
                if (remaining > 1 && remaining < 40 && remaining % 2 != 0)
                {
                    // Never aim to score an odd remainder exactly in double-out.
                    // Above 32, leave the familiar D16; below it, S1 leaves an even finish.
                    return new AimTarget(remaining > 32 ? remaining - 32 : 1, 1, skill);
                }
                if (remaining > 40 && remaining <= 60)
                    return new AimTarget(remaining - 40, 1, skill);
            }
            else if (remaining <= 20)
            {
                return new AimTarget(remaining, 1, skill);
            }

            if (remaining <= 60 && remaining % 3 == 0)
                return new AimTarget(remaining / 3, 3, skill);

            var attacksTriple = strategy == OpponentStrategy.Aggressive
                ? skill >= .34f
                : strategy == OpponentStrategy.Adaptive
                    ? skill >= .4f
                    : strategy == OpponentStrategy.CheckoutSpecialist
                        ? skill >= .58f && aggression >= .4f
                        : strategy == OpponentStrategy.Rhythm
                            ? skill >= .45f && (aggression >= .45f || dartsAvailable == 1)
                            : false;
            return new AimTarget(preferredBase, attacksTriple ? 3 : 1, skill);
        }
    }
}
