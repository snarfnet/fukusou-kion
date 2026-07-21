using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class BallisticSolverTests
    {
        [TestCase(0f)]
        [TestCase(2f)]
        [TestCase(-2f)]
        public void ReachesRequestedHeight(float targetY)
        {
            const float gravity = 9.81f;
            var solution = BallisticSolver.SolveLowArc(0f, 0f, 0f, 0f, targetY, 10f, 16f, gravity);
            Assert.That(solution.Reachable, Is.True);
            var time = solution.FlightTime;
            var simulatedY = solution.VelocityY * time - .5f * gravity * time * time;
            var simulatedZ = solution.VelocityZ * time;
            Assert.That(simulatedY, Is.EqualTo(targetY).Within(.001f));
            Assert.That(simulatedZ, Is.EqualTo(10f).Within(.001f));
        }

        [Test] public void UsesRequestedLaunchSpeed()
        {
            var solution = BallisticSolver.SolveLowArc(0f, -1f, -5f, 1f, 1f, 0f, 16f, 9.81f);
            var speed = System.Math.Sqrt(solution.VelocityX * solution.VelocityX
                + solution.VelocityY * solution.VelocityY + solution.VelocityZ * solution.VelocityZ);
            Assert.That(speed, Is.EqualTo(16f).Within(.001f));
        }

        [Test] public void ReportsUnreachableTarget()
        {
            var solution = BallisticSolver.SolveLowArc(0f, 0f, 0f, 0f, 100f, 100f, 1f, 9.81f);
            Assert.That(solution.Reachable, Is.False);
        }
    }
}
