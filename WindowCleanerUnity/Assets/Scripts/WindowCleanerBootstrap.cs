using UnityEngine;

namespace GlassCraft
{
    public static class WindowCleanerBootstrap
    {
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void StartGame()
        {
            Application.targetFrameRate = 60;
            Screen.orientation = ScreenOrientation.LandscapeLeft;

            if (Object.FindFirstObjectByType<WindowCleaningGame>() == null)
            {
                var root = new GameObject("GlassCraftGame");
                root.AddComponent<WindowCleaningGame>();
            }
        }
    }
}
