using UnityEngine;
using UnityEngine.UI;

namespace ShinobiZero.Runtime
{
    public sealed class DesktopQuitController : MonoBehaviour
    {
        [SerializeField] private Button quitButton;
        [SerializeField] private PlayerProgressController progress;

        private void Awake()
        {
            if (quitButton == null) return;
            var desktop = !Application.isMobilePlatform;
            quitButton.gameObject.SetActive(desktop);
            if (desktop) quitButton.onClick.AddListener(Quit);
        }

        private void OnDestroy()
        {
            if (quitButton != null) quitButton.onClick.RemoveListener(Quit);
        }

        private void Quit()
        {
            if (progress != null) progress.FlushForExit();
            HapticFeedback.Stop();
            AudioListener.pause = false;
            Application.Quit();
        }
    }
}
