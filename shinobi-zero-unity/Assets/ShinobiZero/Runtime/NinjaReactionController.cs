using System.Collections;
using ShinobiZero.Core;
using UnityEngine;

namespace ShinobiZero.Runtime
{
    public sealed class NinjaReactionController : MonoBehaviour
    {
        [SerializeField] private MatchCoordinator coordinator;
        [SerializeField] private NinjaThrowAnimator throwAnimator;
        [SerializeField] private Transform characterRoot;
        [SerializeField] private Transform torso;
        [SerializeField] private Transform head;

        public bool ReducedMotion { get; set; }

        private Vector3 _rootRest;
        private Quaternion _torsoRest;
        private Quaternion _headRest;
        private float _restraint = 1f;
        private Coroutine _reaction;
        private bool _initialized;

        private void Awake() => CaptureRestPose();

        private void CaptureRestPose()
        {
            if (characterRoot != null) _rootRest = characterRoot.localPosition;
            if (torso != null) _torsoRest = torso.localRotation;
            if (head != null) _headRest = head.localRotation;
            _initialized = true;
        }

        private void OnEnable()
        {
            if (coordinator == null) return;
            coordinator.ThrowResolved += HandleThrowResolved;
            coordinator.PausedChanged += HandlePausedChanged;
            coordinator.MatchAborted += CancelReaction;
        }

        private void OnDisable()
        {
            if (coordinator != null)
            {
                coordinator.ThrowResolved -= HandleThrowResolved;
                coordinator.PausedChanged -= HandlePausedChanged;
                coordinator.MatchAborted -= CancelReaction;
            }
            CancelReaction();
        }

        public void Configure(OpponentProfile profile)
        {
            if (!_initialized) CaptureRestPose();
            CancelReaction();
            _restraint = profile == null ? 1f : Mathf.Lerp(1.15f, .72f, profile.PressureResistance);
        }

        public void CancelReaction()
        {
            if (_reaction != null) StopCoroutine(_reaction);
            _reaction = null;
            RestorePose();
        }

        private void HandlePausedChanged(bool paused)
        {
            if (paused) CancelReaction();
        }

        private void HandleThrowResolved(ThrowOutcome outcome)
        {
            var pose = NinjaReactionModel.Evaluate(outcome);
            if (pose.Type == NinjaReactionType.None) return;
            if (ReducedMotion && pose.Type != NinjaReactionType.Victory && pose.Type != NinjaReactionType.Defeat) return;
            if (_reaction != null) StopCoroutine(_reaction);
            _reaction = StartCoroutine(PlayReaction(pose));
        }

        private IEnumerator PlayReaction(NinjaReactionPose pose)
        {
            var wait = 0f;
            while (throwAnimator != null && throwAnimator.IsThrowing && wait < .75f)
            {
                wait += Time.deltaTime;
                yield return null;
            }
            var duration = ReducedMotion ? .18f : pose.Duration;
            var intensity = _restraint * (ReducedMotion ? .3f : 1f);
            var elapsed = 0f;
            while (elapsed < duration)
            {
                if (throwAnimator != null && throwAnimator.IsThrowing) break;
                elapsed += Time.deltaTime;
                var normalized = Mathf.Clamp01(elapsed / duration);
                var pulse = Mathf.Sin(normalized * Mathf.PI);
                if (characterRoot != null) characterRoot.localPosition = _rootRest + Vector3.up * pose.VerticalShift * pulse * intensity;
                if (torso != null) torso.localRotation = _torsoRest * Quaternion.AngleAxis(pose.TorsoPitch * pulse * intensity, Vector3.right);
                if (head != null) head.localRotation = _headRest * Quaternion.AngleAxis(pose.HeadYaw * pulse * intensity, Vector3.up);
                yield return null;
            }
            RestorePose();
            _reaction = null;
        }

        private void RestorePose()
        {
            if (!_initialized) return;
            if (characterRoot != null) characterRoot.localPosition = _rootRest;
            if (torso != null) torso.localRotation = _torsoRest;
            if (head != null) head.localRotation = _headRest;
        }
    }
}
