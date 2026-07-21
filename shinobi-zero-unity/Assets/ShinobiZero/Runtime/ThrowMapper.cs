using ShinobiZero.Core;
using UnityEngine;

namespace ShinobiZero.Runtime
{
    public readonly struct ThrowIntent
    {
        public readonly Vector2 BoardPoint;
        public readonly float Power;
        public readonly float Spin;

        public ThrowIntent(Vector2 boardPoint, float power, float spin)
        {
            BoardPoint = boardPoint;
            Power = power;
            Spin = spin;
        }
    }

    [CreateAssetMenu(menuName = "SHINOBI ZERO/Throw Tuning")]
    public sealed class ThrowMapper : ScriptableObject
    {
        [SerializeField, Range(.15f, .65f)] private float idealRiseFraction = .34f;
        [SerializeField, Range(.2f, 3f)] private float horizontalSensitivity = 1f;
        [SerializeField, Range(.2f, 2f)] private float verticalSensitivity = 1.1f;
        [SerializeField, Range(1f, 100f)] private float spinSensitivity = 45f;
        public float IdealRiseFraction { get { return idealRiseFraction; } }

        public void SetIdealRiseFraction(float value) =>
            idealRiseFraction = Mathf.Clamp(value, ThrowCalibrationModel.MinimumIdealRise, ThrowCalibrationModel.MaximumIdealRise);

        public ThrowIntent Map(ThrowGesture gesture, Vector2 aimAnchor)
        {
            var delta = gesture.NormalizedDelta;
            var solution = ThrowInputModel.Map(
                delta.x, delta.y, gesture.Duration, aimAnchor.x, aimAnchor.y,
                idealRiseFraction, horizontalSensitivity, verticalSensitivity, spinSensitivity);
            return new ThrowIntent(
                Vector2.ClampMagnitude(new Vector2(solution.BoardX, solution.BoardY), 1.25f),
                solution.Power,
                solution.Spin);
        }
    }
}
