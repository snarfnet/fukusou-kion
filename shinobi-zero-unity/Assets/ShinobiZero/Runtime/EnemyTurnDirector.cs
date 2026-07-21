using System.Collections;
using ShinobiZero.Core;
using UnityEngine;

namespace ShinobiZero.Runtime
{
    public sealed class EnemyTurnDirector : MonoBehaviour
    {
        [SerializeField] private MatchCoordinator coordinator;
        [SerializeField] private OpponentProfile profile;
        private readonly OpponentBrain _brain = new OpponentBrain();
        private Coroutine _pendingThrow;
        public OpponentProfile Profile { get { return profile; } }

        public void Configure(OpponentProfile opponent)
        {
            if (_pendingThrow != null) StopCoroutine(_pendingThrow);
            _pendingThrow = null;
            profile = opponent;
        }

        public void CancelPendingThrow()
        {
            if (_pendingThrow != null) StopCoroutine(_pendingThrow);
            _pendingThrow = null;
        }

        public bool BeginTurnIfNeeded(float transitionDelay = 0f)
        {
            if (profile == null || coordinator == null || coordinator.IsPaused || !coordinator.Match.HasStarted
                || coordinator.Match.IsFinished || coordinator.Match.Turn != Combatant.Enemy) return false;
            ScheduleThrow(transitionDelay);
            return true;
        }

        private void OnEnable()
        {
            if (coordinator != null) coordinator.ThrowResolved += HandleThrowResolved;
            if (coordinator != null) coordinator.PausedChanged += HandlePausedChanged;
        }

        private void OnDisable()
        {
            if (coordinator != null) coordinator.ThrowResolved -= HandleThrowResolved;
            if (coordinator != null) coordinator.PausedChanged -= HandlePausedChanged;
            if (_pendingThrow != null) StopCoroutine(_pendingThrow);
        }

        private void HandleThrowResolved(ThrowOutcome outcome)
        {
            if (profile == null || outcome.MatchEnded || coordinator.Match.Turn != Combatant.Enemy) return;
            ScheduleThrow(outcome.LegEnded ? 1.35f : 0f);
        }

        private void HandlePausedChanged(bool paused)
        {
            if (paused)
            {
                if (_pendingThrow != null) StopCoroutine(_pendingThrow);
                _pendingThrow = null;
                return;
            }
            if (profile != null && coordinator.Match.HasStarted && !coordinator.Match.IsFinished
                && coordinator.Match.Turn == Combatant.Enemy) ScheduleThrow(0f);
        }

        private void ScheduleThrow(float transitionDelay)
        {
            if (coordinator.IsPaused) return;
            if (_pendingThrow != null) StopCoroutine(_pendingThrow);
            _pendingThrow = StartCoroutine(ThrowAfterDelay(transitionDelay));
        }

        private IEnumerator ThrowAfterDelay(float transitionDelay)
        {
            yield return new WaitForSecondsRealtime(profile.ThinkTime + transitionDelay);
            _pendingThrow = null;
            var match = coordinator.Match;
            var pressureSkill = match.EnemyScore <= 60
                ? profile.Skill * Mathf.Lerp(.72f, 1f, profile.PressureResistance)
                : profile.Skill;
            var aim = _brain.Choose(
                match.EnemyScore, match.Config.DoubleOut, pressureSkill,
                profile.PreferredBase, profile.Aggression, match.DartsLeft, profile.Strategy);
            var aimPoint = DartboardAimGeometry.Point(aim);
            var boardPoint = new Vector2(aimPoint.X, aimPoint.Y);
            var checkoutPressure = match.EnemyScore <= 170;
            var sigma = OpponentAccuracyModel.Sigma(
                profile.Skill, profile.Consistency, profile.PressureResistance,
                checkoutPressure, match.DartsLeft);
            var error = OpponentAccuracyModel.Sample(
                sigma, profile.HorizontalBias, Random.value, Random.value);
            boardPoint += new Vector2(error.X, error.Y);
            coordinator.AnimateLaunchAtBoard(boardPoint, 1f, Random.Range(-12f, 12f), profile.AnimationProfile);
        }

    }
}
