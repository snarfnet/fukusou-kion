using ShinobiZero.Core;
using UnityEngine;

namespace ShinobiZero.Runtime
{
    public sealed class AimReticleController : MonoBehaviour
    {
        [SerializeField] private ThrowGestureReader gestureReader;
        [SerializeField] private AlternativeThrowController alternativeInput;
        [SerializeField] private MatchCoordinator coordinator;
        [SerializeField] private TargetBoard target;
        [SerializeField] private Camera aimCamera;
        [SerializeField] private RectTransform aimArea;
        [SerializeField] private RectTransform reticle;

        private void Awake() => reticle.gameObject.SetActive(false);

        private void OnEnable()
        {
            if (gestureReader != null) gestureReader.PointerTracked += HandlePointer;
            if (alternativeInput != null) alternativeInput.AimTracked += HandleBoardAim;
        }

        private void OnDisable()
        {
            if (gestureReader != null) gestureReader.PointerTracked -= HandlePointer;
            if (alternativeInput != null) alternativeInput.AimTracked -= HandleBoardAim;
            if (reticle != null) reticle.gameObject.SetActive(false);
        }

        private void HandlePointer(Vector2 pointer, bool tracking)
        {
            var canAim = CanAim(tracking);
            reticle.gameObject.SetActive(canAim);
            if (!canAim) return;

            var camera = aimCamera != null ? aimCamera : Camera.main;
            if (camera == null || target == null) return;
            var centerWorld = target.BoardPointToWorld(Vector2.zero);
            var edgeWorld = target.BoardPointToWorld(Vector2.right);
            var center = camera.WorldToScreenPoint(centerWorld);
            var edge = camera.WorldToScreenPoint(edgeWorld);
            var radius = Vector2.Distance(new Vector2(center.x, center.y), new Vector2(edge.x, edge.y));
            var aim = ScreenAimModel.Map(pointer.x, pointer.y, center.x, center.y, radius);
            PositionReticle(new Vector2(aim.X, aim.Y), center, radius);
        }

        private void HandleBoardAim(Vector2 boardAim, bool tracking)
        {
            var canAim = CanAim(tracking);
            reticle.gameObject.SetActive(canAim);
            if (!canAim) return;
            var camera = aimCamera != null ? aimCamera : Camera.main;
            if (camera == null || target == null) return;
            var center = camera.WorldToScreenPoint(target.BoardPointToWorld(Vector2.zero));
            var edge = camera.WorldToScreenPoint(target.BoardPointToWorld(Vector2.right));
            var radius = Vector2.Distance(new Vector2(center.x, center.y), new Vector2(edge.x, edge.y));
            PositionReticle(boardAim, center, radius);
        }

        private bool CanAim(bool tracking)
        {
            var match = coordinator.Match;
            return tracking && match.HasStarted && !match.IsFinished && !coordinator.IsPaused
                && match.Turn == Combatant.Player && !coordinator.IsThrowInFlight;
        }

        private void PositionReticle(Vector2 boardAim, Vector3 center, float radius)
        {
            var clampedScreen = new Vector2(center.x + boardAim.x * radius, center.y + boardAim.y * radius);
            if (RectTransformUtility.ScreenPointToLocalPointInRectangle(aimArea, clampedScreen, null, out var localPoint))
                reticle.anchoredPosition = localPoint;
        }
    }
}
