using ShinobiZero.Core;
using UnityEngine;
using UnityEngine.InputSystem;

namespace ShinobiZero.Runtime
{
    public static class InputModeDetector
    {
        public static TutorialInputMode Default()
        {
            if (Gamepad.current != null) return TutorialInputMode.Gamepad;
            return Application.isMobilePlatform ? TutorialInputMode.Touch : TutorialInputMode.KeyboardMouse;
        }

        public static TutorialInputMode Detect(TutorialInputMode fallback)
        {
            if (Touchscreen.current != null && Touchscreen.current.primaryTouch.press.wasPressedThisFrame)
                return TutorialInputMode.Touch;
            var gamepad = Gamepad.current;
            if (gamepad != null && (gamepad.buttonSouth.wasPressedThisFrame || gamepad.buttonEast.wasPressedThisFrame
                || gamepad.startButton.wasPressedThisFrame || gamepad.leftTrigger.ReadValue() > .1f
                || gamepad.rightTrigger.ReadValue() > .1f || gamepad.leftStick.ReadValue().sqrMagnitude > .04f
                || gamepad.rightStick.ReadValue().sqrMagnitude > .04f))
                return TutorialInputMode.Gamepad;
            if ((Keyboard.current != null && Keyboard.current.anyKey.wasPressedThisFrame)
                || (Mouse.current != null && (Mouse.current.leftButton.wasPressedThisFrame || Mouse.current.rightButton.wasPressedThisFrame)))
                return TutorialInputMode.KeyboardMouse;
            return fallback;
        }
    }
}
