using System;
using System.Collections;
using ShinobiZero.Core;
using UnityEngine;

namespace ShinobiZero.Runtime
{
    public sealed class NinjaThrowAnimator : MonoBehaviour
    {
        [SerializeField] private Animator animator;
        [SerializeField] private ThrowAnimationProfile profile;
        [SerializeField] private Transform torso;
        [SerializeField] private Transform shoulder;
        [SerializeField] private Transform elbow;
        [SerializeField] private Transform wrist;
        public event Action ReleaseRequested;
        public bool IsThrowing { get; private set; }
        private Quaternion _torsoRest;
        private Quaternion _shoulderRest;
        private Quaternion _elbowRest;
        private Quaternion _wristRest;
        private ThrowAnimationProfile _activeProfile;

        private void Awake()
        {
            if (torso != null) _torsoRest = torso.localRotation;
            if (shoulder != null) _shoulderRest = shoulder.localRotation;
            if (elbow != null) _elbowRest = elbow.localRotation;
            if (wrist != null) _wristRest = wrist.localRotation;
        }

        public bool PlayThrow()
        {
            return PlayThrow(profile);
        }

        public bool PlayThrow(ThrowAnimationProfile overrideProfile)
        {
            if (IsThrowing || overrideProfile == null) return false;
            IsThrowing = true;
            _activeProfile = overrideProfile;
            if (animator != null)
                animator.CrossFadeInFixedTime(_activeProfile.StateName, _activeProfile.CrossFadeDuration);
            else
                StartCoroutine(PlayProcedural());
            return true;
        }

        private IEnumerator PlayProcedural()
        {
            var elapsed = 0f;
            var released = false;
            while (elapsed < _activeProfile.ThrowDuration)
            {
                var previous = Mathf.Clamp01(elapsed / _activeProfile.ThrowDuration);
                elapsed += Time.deltaTime;
                var normalized = Mathf.Clamp01(elapsed / _activeProfile.ThrowDuration);
                var release = _activeProfile.ReleaseNormalizedTime;
                if (!released && ThrowMotionModel.CrossedRelease(previous, normalized, release))
                { released = true; ReleaseShuriken(); }
                var pose = ThrowMotionModel.Evaluate(normalized, release, _activeProfile.WindupDegrees, _activeProfile.FollowThroughDegrees);
                Pose(pose.Shoulder, pose.Elbow, pose.Wrist, pose.Torso);
                yield return null;
            }
            if (!released) ReleaseShuriken();
            Pose(0f, 0f, 0f, 0f);
            FinishThrow();
        }

        private void Pose(float shoulderAngle, float elbowAngle, float wristAngle, float torsoAngle)
        {
            if (torso != null) torso.localRotation = _torsoRest * Quaternion.AngleAxis(torsoAngle, Vector3.up);
            if (shoulder != null) shoulder.localRotation = _shoulderRest * Quaternion.AngleAxis(shoulderAngle, Vector3.forward);
            if (elbow != null) elbow.localRotation = _elbowRest * Quaternion.AngleAxis(elbowAngle, Vector3.forward);
            if (wrist != null) wrist.localRotation = _wristRest * Quaternion.AngleAxis(wristAngle, Vector3.forward);
        }

        // Call from the release frame's Animation Event.
        public void ReleaseShuriken()
        {
            if (!IsThrowing) return;
            ReleaseRequested?.Invoke();
        }

        // Call from the final frame's Animation Event.
        public void FinishThrow() => IsThrowing = false;

        public void CancelThrow()
        {
            StopAllCoroutines();
            Pose(0f, 0f, 0f, 0f);
            IsThrowing = false;
            _activeProfile = null;
        }
    }
}
