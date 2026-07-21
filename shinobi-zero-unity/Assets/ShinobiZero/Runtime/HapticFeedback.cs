using System.Runtime.InteropServices;
using ShinobiZero.Core;

namespace ShinobiZero.Runtime
{
    public static class HapticFeedback
    {
        private static bool _enabled = true;
        public static bool Enabled
        {
            get { return _enabled; }
            set
            {
                _enabled = value;
                if (!value) Stop();
            }
        }
#if UNITY_IOS && !UNITY_EDITOR
        [DllImport("__Internal")] private static extern void SZ_HapticImpact(int style);
        [DllImport("__Internal")] private static extern void SZ_HapticNotification(int type);
#endif

        public static void LightImpact()
        {
            if (!Enabled) return;
            GamepadRumbleDriver.Play(HapticCue.Light);
#if UNITY_IOS && !UNITY_EDITOR
            SZ_HapticImpact(0);
#endif
        }

        public static void MediumImpact()
        {
            if (!Enabled) return;
            GamepadRumbleDriver.Play(HapticCue.Medium);
#if UNITY_IOS && !UNITY_EDITOR
            SZ_HapticImpact(1);
#endif
        }

        public static void Success()
        {
            if (!Enabled) return;
            GamepadRumbleDriver.Play(HapticCue.Success);
#if UNITY_IOS && !UNITY_EDITOR
            SZ_HapticNotification(0);
#endif
        }

        public static void Error()
        {
            if (!Enabled) return;
            GamepadRumbleDriver.Play(HapticCue.Error);
#if UNITY_IOS && !UNITY_EDITOR
            SZ_HapticNotification(1);
#endif
        }

        public static void Stop() => GamepadRumbleDriver.Stop();
    }
}
