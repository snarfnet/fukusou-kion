using System;

namespace ShinobiZero.Core
{
    public struct ShurikenSpinState
    {
        public readonly float RadiansPerSecond;
        public readonly float RequiredAngularLimit;

        public ShurikenSpinState(float radiansPerSecond, float requiredAngularLimit)
        {
            RadiansPerSecond = radiansPerSecond;
            RequiredAngularLimit = requiredAngularLimit;
        }
    }

    public static class ShurikenFlightModel
    {
        public static ShurikenSpinState Spin(float baseDegreesPerSecond, float biasDegreesPerSecond)
        {
            var radians = (baseDegreesPerSecond + biasDegreesPerSecond) * (float)(Math.PI / 180d);
            return new ShurikenSpinState(radians, Math.Max(7f, Math.Abs(radians) * 1.1f));
        }
    }
}
