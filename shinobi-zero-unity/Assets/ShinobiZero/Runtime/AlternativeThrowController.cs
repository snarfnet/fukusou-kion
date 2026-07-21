using System;
using ShinobiZero.Core;
using UnityEngine;
using UnityEngine.InputSystem;

namespace ShinobiZero.Runtime
{
    public sealed class AlternativeThrowController : MonoBehaviour
    {
        [SerializeField] private MatchCoordinator coordinator;
        [SerializeField, Range(.2f, 2f)] private float aimSpeed = .8f;
        public event Action<Vector2, bool> AimTracked;
        public float AimSensitivity { get; set; } = 1f;

        private Vector2 _aim;
        private bool _charging;
        private float _chargeStarted;

        private void Update()
        {
            if (coordinator == null) return;
            var match = coordinator.Match;
            var canPlay = match.HasStarted && !match.IsFinished && !coordinator.IsPaused
                && match.Turn == Combatant.Player && !coordinator.IsThrowInFlight;
            if (!canPlay)
            {
                if (_charging) { _charging = false; AimTracked?.Invoke(_aim, false); }
                return;
            }

            var movement = ReadAimMovement();
            if (movement.sqrMagnitude > .001f)
            {
                _aim = Vector2.ClampMagnitude(_aim + movement * aimSpeed * AimSensitivity * Time.unscaledDeltaTime, 1.15f);
                AimTracked?.Invoke(_aim, true);
            }

            if (WasChargePressed())
            {
                _charging = true;
                _chargeStarted = Time.unscaledTime;
                AimTracked?.Invoke(_aim, true);
            }
            if (!_charging || !WasChargeReleased()) return;
            _charging = false;
            var spin = Gamepad.current == null ? 0f : Gamepad.current.rightStick.x.ReadValue();
            var solution = ButtonThrowModel.Map(_aim.x, _aim.y, Time.unscaledTime - _chargeStarted, spin);
            if (solution.Valid)
                coordinator.TryPlayerThrow(new Vector2(solution.BoardX, solution.BoardY), solution.Power, solution.Spin);
            AimTracked?.Invoke(_aim, false);
        }

        private static Vector2 ReadAimMovement()
        {
            var movement = Gamepad.current == null ? Vector2.zero : Gamepad.current.leftStick.ReadValue();
            if (Keyboard.current == null) return movement;
            var x = (Keyboard.current.dKey.isPressed || Keyboard.current.rightArrowKey.isPressed ? 1f : 0f)
                - (Keyboard.current.aKey.isPressed || Keyboard.current.leftArrowKey.isPressed ? 1f : 0f);
            var y = (Keyboard.current.wKey.isPressed || Keyboard.current.upArrowKey.isPressed ? 1f : 0f)
                - (Keyboard.current.sKey.isPressed || Keyboard.current.downArrowKey.isPressed ? 1f : 0f);
            var keyboard = Vector2.ClampMagnitude(new Vector2(x, y), 1f);
            return keyboard.sqrMagnitude > movement.sqrMagnitude ? keyboard : movement;
        }

        private static bool WasChargePressed() =>
            (Gamepad.current != null && Gamepad.current.rightTrigger.wasPressedThisFrame)
            || (Keyboard.current != null && Keyboard.current.fKey.wasPressedThisFrame);

        private static bool WasChargeReleased() =>
            (Gamepad.current != null && Gamepad.current.rightTrigger.wasReleasedThisFrame)
            || (Keyboard.current != null && Keyboard.current.fKey.wasReleasedThisFrame);
    }
}
