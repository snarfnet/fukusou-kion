using ShinobiZero.Core;
using UnityEngine;

namespace ShinobiZero.Runtime
{
    public sealed class TargetBoard : MonoBehaviour
    {
        [SerializeField, Min(.01f)] private float scoringRadius = .5f;
        [SerializeField] private float surfaceLocalZ = -.5f;
        public float SurfaceLocalZ { get { return surfaceLocalZ; } }

        public DartHit ScoreWorldPoint(Vector3 worldPoint)
        {
            var local = transform.InverseTransformPoint(worldPoint);
            return DartboardGeometry.Score(local.x / scoringRadius, local.y / scoringRadius);
        }

        public Vector3 BoardPointToWorld(Vector2 normalizedPoint, float surfaceOffset = 0f)
        {
            return transform.TransformPoint(new Vector3(
                normalizedPoint.x * scoringRadius,
                normalizedPoint.y * scoringRadius,
                surfaceLocalZ + surfaceOffset));
        }
    }
}
