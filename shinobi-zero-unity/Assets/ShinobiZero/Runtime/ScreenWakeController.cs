using ShinobiZero.Core;
using UnityEngine;

namespace ShinobiZero.Runtime
{
    public sealed class ScreenWakeController : MonoBehaviour
    {
        [SerializeField] private MatchCoordinator coordinator;
        [SerializeField] private GameFlowController flow;
        private bool _matchActive;
        private bool _focused = true;
        private bool _suspended;

        private void OnEnable()
        {
            if (flow != null) flow.MatchStarted += HandleMatchStarted;
            if (coordinator != null)
            {
                coordinator.ThrowResolved += HandleThrowResolved;
                coordinator.MatchAborted += HandleMatchAborted;
                coordinator.PausedChanged += HandlePausedChanged;
            }
            Apply();
        }

        private void OnDisable()
        {
            if (flow != null) flow.MatchStarted -= HandleMatchStarted;
            if (coordinator != null)
            {
                coordinator.ThrowResolved -= HandleThrowResolved;
                coordinator.MatchAborted -= HandleMatchAborted;
                coordinator.PausedChanged -= HandlePausedChanged;
            }
            if (Application.isMobilePlatform) Screen.sleepTimeout = SleepTimeout.SystemSetting;
        }

        private void HandleMatchStarted()
        {
            _matchActive = true;
            Apply();
        }

        private void HandleThrowResolved(ThrowOutcome outcome)
        {
            if (outcome.MatchEnded) _matchActive = false;
            Apply();
        }

        private void HandleMatchAborted()
        {
            _matchActive = false;
            Apply();
        }

        private void HandlePausedChanged(bool paused) => Apply();

        private void OnApplicationFocus(bool focused)
        {
            _focused = focused;
            Apply();
        }

        private void OnApplicationPause(bool suspended)
        {
            _suspended = suspended;
            Apply();
        }

        private void Apply()
        {
            if (!Application.isMobilePlatform) return;
            var match = coordinator == null ? null : coordinator.Match;
            var prevent = ScreenWakePolicy.ShouldPreventSleep(
                _matchActive, match != null && match.IsFinished, coordinator != null && coordinator.IsPaused,
                _focused, _suspended);
            Screen.sleepTimeout = prevent ? SleepTimeout.NeverSleep : SleepTimeout.SystemSetting;
        }
    }
}
