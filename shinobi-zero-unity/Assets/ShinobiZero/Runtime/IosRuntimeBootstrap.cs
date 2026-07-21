using UnityEngine;

namespace ShinobiZero.Runtime
{
    public sealed class IosRuntimeBootstrap : MonoBehaviour
    {
        private void Awake()
        {
            QualitySettings.vSyncCount = 0;
            Application.targetFrameRate = 60;
            Screen.sleepTimeout = SleepTimeout.SystemSetting;
        }
    }
}
