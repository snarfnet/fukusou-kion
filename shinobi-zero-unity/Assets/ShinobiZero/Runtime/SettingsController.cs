using ShinobiZero.Core;
using UnityEngine;
using UnityEngine.UI;

namespace ShinobiZero.Runtime
{
    public sealed class SettingsController : MonoBehaviour
    {
        private const string PreferencesKey = "shinobi-zero.preferences.v1";
        [SerializeField] private GameObject panel;
        [SerializeField] private Button openButton;
        [SerializeField] private Button closeButton;
        [SerializeField] private Toggle soundToggle;
        [SerializeField] private Toggle hapticsToggle;
        [SerializeField] private Toggle reducedMotionToggle;
        [SerializeField] private Toggle englishToggle;
        [SerializeField] private Toggle fullscreenToggle;
        [SerializeField] private ThrowFeedbackController feedback;
        [SerializeField] private FirstPersonThrowAnimator playerThrowAnimator;
        [SerializeField] private NinjaReactionController ninjaReaction;
        [SerializeField] private TitleBackgroundController titleBackground;
        [SerializeField] private UiLocalizationController localization;
        [SerializeField] private GameHudController hud;

        private void Awake()
        {
            openButton.onClick.AddListener(() => panel.SetActive(true));
            closeButton.onClick.AddListener(() => panel.SetActive(false));
            var preferences = PreferencesCodec.Decode(PlayerPrefs.GetInt(PreferencesKey, 0));
            soundToggle.SetIsOnWithoutNotify(preferences.SoundEnabled);
            hapticsToggle.SetIsOnWithoutNotify(preferences.HapticsEnabled);
            reducedMotionToggle.SetIsOnWithoutNotify(preferences.ReducedMotion);
            englishToggle.SetIsOnWithoutNotify(preferences.EnglishUi);
            fullscreenToggle.SetIsOnWithoutNotify(preferences.Fullscreen);
            fullscreenToggle.gameObject.SetActive(!Application.isMobilePlatform);
            soundToggle.onValueChanged.AddListener(_ => ApplyAndSave());
            hapticsToggle.onValueChanged.AddListener(_ => ApplyAndSave());
            reducedMotionToggle.onValueChanged.AddListener(_ => ApplyAndSave());
            englishToggle.onValueChanged.AddListener(_ => ApplyAndSave());
            fullscreenToggle.onValueChanged.AddListener(_ => ApplyAndSave());
            panel.SetActive(false);
            Apply(preferences);
        }

        private void ApplyAndSave()
        {
            var preferences = new GamePreferences(soundToggle.isOn, hapticsToggle.isOn, reducedMotionToggle.isOn, englishToggle.isOn, fullscreenToggle.isOn);
            Apply(preferences);
            PlayerPrefs.SetInt(PreferencesKey, PreferencesCodec.Encode(preferences));
            PlayerPrefs.Save();
        }

        private void Apply(GamePreferences preferences)
        {
            AudioListener.volume = preferences.SoundEnabled ? 1f : 0f;
            HapticFeedback.Enabled = preferences.HapticsEnabled;
            if (feedback != null) feedback.ReducedMotion = preferences.ReducedMotion;
            if (playerThrowAnimator != null) playerThrowAnimator.ReducedMotion = preferences.ReducedMotion;
            if (ninjaReaction != null) ninjaReaction.ReducedMotion = preferences.ReducedMotion;
            if (titleBackground != null) titleBackground.ReducedMotion = preferences.ReducedMotion;
            if (hud != null) hud.ReducedMotion = preferences.ReducedMotion;
            if (localization != null) localization.SetLanguage(preferences.EnglishUi ? GameLanguage.English : GameLanguage.Japanese);
            if (!Application.isMobilePlatform)
                Screen.fullScreenMode = preferences.Fullscreen ? FullScreenMode.FullScreenWindow : FullScreenMode.Windowed;
        }
    }
}
