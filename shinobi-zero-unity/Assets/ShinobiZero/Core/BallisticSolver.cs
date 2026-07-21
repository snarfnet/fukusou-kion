using System;

namespace ShinobiZero.Core
{
    public struct BallisticSolution
    {
        public readonly bool Reachable;
        public readonly float VelocityX;
        public readonly float VelocityY;
        public readonly float VelocityZ;
        public readonly float FlightTime;

        public BallisticSolution(bool reachable, float velocityX, float velocityY, float velocityZ, float flightTime)
        {
            Reachable = reachable;
            VelocityX = velocityX;
            VelocityY = velocityY;
            VelocityZ = velocityZ;
            FlightTime = flightTime;
        }

        public static BallisticSolution None { get { return new BallisticSolution(false, 0f, 0f, 0f, 0f); } }
    }

    public static class BallisticSolver
    {
        public static BallisticSolution SolveLowArc(
            float originX, float originY, float originZ,
            float targetX, float targetY, float targetZ,
            float speed, float gravity)
        {
            if (speed <= 0f || gravity <= 0f) return BallisticSolution.None;
            var deltaX = targetX - originX;
            var deltaY = targetY - originY;
            var deltaZ = targetZ - originZ;
            var horizontal = Math.Sqrt(deltaX * deltaX + deltaZ * deltaZ);
            if (horizontal < .000001d) return BallisticSolution.None;

            var speedSquared = speed * speed;
            var discriminant = speedSquared * speedSquared
                - gravity * (gravity * horizontal * horizontal + 2d * deltaY * speedSquared);
            if (discriminant < 0d) return BallisticSolution.None;

            var tangent = (speedSquared - Math.Sqrt(discriminant)) / (gravity * horizontal);
            var cosine = 1d / Math.Sqrt(1d + tangent * tangent);
            var sine = tangent * cosine;
            var horizontalSpeed = speed * cosine;
            var inverseHorizontal = 1d / horizontal;
            var velocityX = deltaX * inverseHorizontal * horizontalSpeed;
            var velocityZ = deltaZ * inverseHorizontal * horizontalSpeed;
            var velocityY = speed * sine;
            var flightTime = horizontal / horizontalSpeed;
            return new BallisticSolution(true, (float)velocityX, (float)velocityY, (float)velocityZ, (float)flightTime);
        }
    }
}
