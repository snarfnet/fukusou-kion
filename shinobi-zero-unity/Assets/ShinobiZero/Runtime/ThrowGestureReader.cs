using System;
using System.Collections.Generic;
using ShinobiZero.Core;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem;
using UnityEngine.UI;

namespace ShinobiZero.Runtime
{
    public readonly struct ThrowGesture
    {
        public readonly Vector2 Start;
        public readonly Vector2 End;
        public readonly Vector2 ScreenSize;
        public readonly float Duration;
        public Vector2 Delta => End - Start;
        public float Speed => Duration <= 0f ? 0f : Delta.magnitude / Duration;
        public Vector2 NormalizedDelta => new Vector2(
            ScreenSize.x <= 0f ? 0f : Delta.x / ScreenSize.x,
            ScreenSize.y <= 0f ? 0f : Delta.y / ScreenSize.y);

        public ThrowGesture(Vector2 start, Vector2 end, float duration, Vector2 screenSize)
        {
            Start = start;
            End = end;
            Duration = duration;
            ScreenSize = screenSize;
        }
    }

    public sealed class ThrowGestureReader : MonoBehaviour
    {
        [SerializeField, Range(.02f, .3f)] private float minimumRiseFraction = .08f;
        [SerializeField, Range(.05f, 1f)] private float minimumUpwardSpeed = .18f;
        [SerializeField, Range(.3f, 3f)] private float maximumDuration = 1.4f;
        public event Action<ThrowGesture> Thrown;
        public event Action<Vector2, bool> PointerTracked;
        public event Action<ThrowRejectionReason> Rejected;

        private bool _tracking;
        private Vector2 _start;
        private float _startedAt;
        private static readonly List<RaycastResult> UiHits = new List<RaycastResult>();

        private void Update()
        {
            if (TryReadPointer(out var position, out var pressed, out var released))
            {
                if (pressed)
                {
                    if (IsOverInteractiveUi(position)) CancelTracking();
                    else Begin(position);
                }
                if (_tracking && !released) PointerTracked?.Invoke(position, true);
                if (released) End(position);
            }
        }

        private void OnDisable() => CancelTracking();
        private void OnApplicationPause(bool paused) { if (paused) CancelTracking(); }
        private void OnApplicationFocus(bool focused) { if (!focused) CancelTracking(); }

        public bool CancelTracking()
        {
            if (!_tracking) return false;
            _tracking = false;
            PointerTracked?.Invoke(_start, false);
            return true;
        }

        private void Begin(Vector2 position)
        {
            _tracking = true;
            _start = position;
            _startedAt = Time.unscaledTime;
        }

        private void End(Vector2 position)
        {
            if (!_tracking) return;
            _tracking = false;
            PointerTracked?.Invoke(position, false);
            var gesture = new ThrowGesture(_start, position, Time.unscaledTime - _startedAt, new Vector2(Screen.width, Screen.height));
            var rejection = ThrowInputModel.Validate(
                gesture.NormalizedDelta.y, gesture.Duration, minimumRiseFraction, minimumUpwardSpeed, maximumDuration);
            if (rejection == ThrowRejectionReason.None)
                Thrown?.Invoke(gesture);
            else
                Rejected?.Invoke(rejection);
        }

        private static bool TryReadPointer(out Vector2 position, out bool pressed, out bool released)
        {
            if (Touchscreen.current != null)
            {
                var touch = Touchscreen.current.primaryTouch;
                position = touch.position.ReadValue();
                pressed = touch.press.wasPressedThisFrame;
                released = touch.press.wasReleasedThisFrame;
                if (pressed || released || touch.press.isPressed) return true;
            }

            if (Mouse.current != null)
            {
                position = Mouse.current.position.ReadValue();
                pressed = Mouse.current.leftButton.wasPressedThisFrame;
                released = Mouse.current.leftButton.wasReleasedThisFrame;
                return true;
            }

            position = default;
            pressed = released = false;
            return false;
        }

        private static bool IsOverInteractiveUi(Vector2 position)
        {
            var eventSystem = EventSystem.current;
            if (eventSystem == null) return false;
            UiHits.Clear();
            eventSystem.RaycastAll(new PointerEventData(eventSystem) { position = position }, UiHits);
            for (var i = 0; i < UiHits.Count; i++)
            {
                var selectable = UiHits[i].gameObject.GetComponentInParent<Selectable>();
                if (selectable != null && selectable.isActiveAndEnabled && selectable.interactable)
                {
                    UiHits.Clear();
                    return true;
                }
            }
            UiHits.Clear();
            return false;
        }
    }
}
