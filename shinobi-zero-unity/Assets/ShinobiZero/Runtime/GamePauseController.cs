using UnityEngine;
using UnityEngine.UI;
using UnityEngine.InputSystem;
using ShinobiZero.Core;

namespace ShinobiZero.Runtime
{
    public sealed class GamePauseController : MonoBehaviour
    {
        [SerializeField] private MatchCoordinator coordinator;
        [SerializeField] private GameFlowController flow;
        [SerializeField] private GameObject panel;
        [SerializeField] private Button pauseButton;
        [SerializeField] private Button resumeButton;
        [SerializeField] private Button exitButton;
        private bool _applicationFocused = true;
        private bool _applicationSuspended;
        private bool _platformOverlay;

        private void Awake()
        {
            pauseButton.onClick.AddListener(Pause);
            resumeButton.onClick.AddListener(Resume);
            exitButton.onClick.AddListener(ExitMatch);
            panel.SetActive(false);
        }

        private void OnEnable()
        {
            PlatformActivityState.OverlayChanged += HandleOverlayChanged;
            _platformOverlay = PlatformActivityState.OverlayActive;
            if (_platformOverlay) HandleOverlayChanged(true);
        }

        private void OnDisable()
        {
            PlatformActivityState.OverlayChanged -= HandleOverlayChanged;
            if (coordinator != null && coordinator.IsPaused) coordinator.SetPaused(false);
            Time.timeScale = 1f;
            AudioListener.pause = false;
        }

        private void OnApplicationPause(bool paused)
        {
            _applicationSuspended = paused;
            if (paused) Pause();
            RefreshAudioPause();
        }

        private void OnApplicationFocus(bool focused)
        {
            _applicationFocused = focused;
            if (!focused) Pause();
            RefreshAudioPause();
        }

        private void Update()
        {
            if (_platformOverlay) return;
            var togglePressed = (Keyboard.current != null && Keyboard.current.escapeKey.wasPressedThisFrame)
                || (Gamepad.current != null && (Gamepad.current.startButton.wasPressedThisFrame
                    || Gamepad.current.buttonEast.wasPressedThisFrame));
            if (!togglePressed) return;
            if (coordinator != null && coordinator.IsPaused) Resume();
            else Pause();
        }

        public void Pause()
        {
            HapticFeedback.Stop();
            if (coordinator == null || !coordinator.Match.HasStarted || coordinator.Match.IsFinished) return;
            coordinator.SetPaused(true);
            Time.timeScale = 0f;
            RefreshAudioPause();
            panel.SetActive(true);
        }

        public void Resume()
        {
            if (!ApplicationLifecycleModel.CanResume(_applicationFocused, _applicationSuspended, _platformOverlay)) return;
            coordinator.SetPaused(false);
            Time.timeScale = 1f;
            RefreshAudioPause();
            panel.SetActive(false);
        }

        private void ExitMatch()
        {
            Time.timeScale = 1f;
            panel.SetActive(false);
            flow.AbortMatch();
            RefreshAudioPause();
        }

        private void RefreshAudioPause()
        {
            AudioListener.pause = ApplicationLifecycleModel.ShouldPauseAudio(
                _applicationFocused, _applicationSuspended, coordinator != null && coordinator.IsPaused, _platformOverlay);
        }

        private void HandleOverlayChanged(bool active)
        {
            _platformOverlay = active;
            if (active) Pause();
            RefreshAudioPause();
        }
    }
}
