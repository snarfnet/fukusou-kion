using ShinobiZero.Core;
using UnityEngine;
using UnityEngine.InputSystem;

namespace ShinobiZero.Runtime
{
    public sealed class GamepadRumbleDriver : MonoBehaviour
    {
        private static GamepadRumbleDriver _instance;
        private Gamepad _activeGamepad;
        private float _stopAt;

        private void Awake() => _instance = this;

        private void OnEnable() => InputSystem.onDeviceChange += HandleDeviceChange;

        private void Update()
        {
            if (_activeGamepad == null || Time.unscaledTime < _stopAt) return;
            StopCurrent();
        }

        private void OnDisable()
        {
            InputSystem.onDeviceChange -= HandleDeviceChange;
            StopCurrent();
            if (_instance == this) _instance = null;
        }

        private void HandleDeviceChange(InputDevice device, InputDeviceChange change)
        {
            if (device != _activeGamepad) return;
            if (change == InputDeviceChange.Removed || change == InputDeviceChange.Disconnected
                || change == InputDeviceChange.Disabled) StopCurrent();
        }

        public static void Play(HapticCue cue)
        {
            if (_instance == null || Gamepad.current == null) return;
            var pulse = HapticPulseModel.Get(cue);
            _instance.StartPulse(Gamepad.current, pulse);
        }

        public static void Stop()
        {
            if (_instance != null) _instance.StopCurrent();
        }

        private void StartPulse(Gamepad gamepad, HapticPulse pulse)
        {
            if (_activeGamepad != null && _activeGamepad != gamepad) StopCurrent();
            _activeGamepad = gamepad;
            _stopAt = Time.unscaledTime + pulse.Duration;
            _activeGamepad.SetMotorSpeeds(pulse.LowFrequency, pulse.HighFrequency);
        }

        private void StopCurrent()
        {
            if (_activeGamepad != null)
            {
                try { _activeGamepad.SetMotorSpeeds(0f, 0f); }
                catch (System.Exception) { }
            }
            _activeGamepad = null;
            _stopAt = 0f;
        }
    }
}
