using NUnit.Framework;
using ShinobiZero.Runtime;
using UnityEngine;

namespace ShinobiZero.Tests
{
    public sealed class TargetBoardTests
    {
        [Test] public void BoardPointRoundTripsThroughWorldSpace()
        {
            var gameObject = new GameObject("Board Test");
            try
            {
                gameObject.transform.position = new Vector3(2f, 3f, 4f);
                gameObject.transform.rotation = Quaternion.Euler(0f, 20f, 0f);
                var board = gameObject.AddComponent<TargetBoard>();
                var world = board.BoardPointToWorld(new Vector2(0f, .62f));
                var hit = board.ScoreWorldPoint(world);
                Assert.That(hit.Segment, Is.EqualTo(20));
                Assert.That(hit.Multiplier, Is.EqualTo(3));
            }
            finally
            {
                Object.DestroyImmediate(gameObject);
            }
        }

        [Test] public void SurfaceOffsetMovesTowardLocalPositiveZ()
        {
            var gameObject = new GameObject("Board Surface Test");
            try
            {
                var board = gameObject.AddComponent<TargetBoard>();
                var surface = board.BoardPointToWorld(Vector2.zero);
                var clear = board.BoardPointToWorld(Vector2.zero, .02f);
                Assert.That(clear.z - surface.z, Is.EqualTo(.02f).Within(.0001f));
            }
            finally
            {
                Object.DestroyImmediate(gameObject);
            }
        }
    }
}
