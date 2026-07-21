using System;
using System.Collections;
using ShinobiZero.Core;
using UnityEngine;

namespace ShinobiZero.Runtime
{
    public sealed class FirstPersonThrowAnimator : MonoBehaviour
    {
        [SerializeField] private Transform shoulder;
        [SerializeField] private Transform elbow;
        [SerializeField] private Transform wrist;
        [SerializeField] private GameObject heldShuriken;

        public event Action ReleaseRequested;
        public bool IsThrowing { get; private set; }
        public bool ReducedMotion { get; set; }

        private Quaternion _shoulderRest;
        private Quaternion _elbowRest;
        private Quaternion _wristRest;
        private Coroutine _routine;
        private bool _recoverAfterThrow;
        private readonly ThrowReleaseGate _releaseGate = new ThrowReleaseGate();

        private void Awake()
        {
            if (shoulder != null) _shoulderRest = shoulder.localRotation;
            if (elbow != null) _elbowRest = elbow.localRotation;
            if (wrist != null) _wristRest = wrist.localRotation;
        }

        public bool PlayThrow(float power, float spin)
        {
            if (IsThrowing) return false;
            IsThrowing = true;
            _releaseGate.Arm();
            _recoverAfterThrow = false;
            if (heldShuriken != null) heldShuriken.SetActive(true);
            _routine = StartCoroutine(Animate(PlayerThrowMotionModel.Tune(power, spin, ReducedMotion)));
            return true;
        }

        public void SetMatchActive(bool active)
        {
            if (!active) CancelThrow();
            gameObject.SetActive(active);
            if (active) RecoverHeldShuriken();
        }

        public void RecoverHeldShuriken()
        {
            if (IsThrowing) { _recoverAfterThrow = true; return; }
            if (heldShuriken != null) heldShuriken.SetActive(true);
        }

        public void HideHeldShuriken()
        {
            _recoverAfterThrow = false;
            if (heldShuriken != null) heldShuriken.SetActive(false);
        }

        public void CancelThrow()
        {
            if (_routine != null) StopCoroutine(_routine);
            _routine = null;
            _recoverAfterThrow = false;
            IsThrowing = false;
            _releaseGate.Reset();
            Pose(0f, 0f, 0f);
            HideHeldShuriken();
        }

        private IEnumerator Animate(PlayerThrowMotionTuning tuning)
        {
            var elapsed = 0f;
            while (elapsed < tuning.Duration)
            {
                var previous = Mathf.Clamp01(elapsed / tuning.Duration);
                elapsed += Time.deltaTime;
                var normalized = Mathf.Clamp01(elapsed / tuning.Duration);
                if (ThrowMotionModel.CrossedRelease(previous, normalized, tuning.ReleaseTime) && _releaseGate.TryRelease())
                {
                    HideHeldShuriken();
                    ReleaseRequested?.Invoke();
                }
                var pose = ThrowMotionModel.Evaluate(normalized, tuning.ReleaseTime, tuning.Windup, tuning.FollowThrough);
                Pose(pose.Shoulder, pose.Elbow, pose.Wrist + tuning.WristBias);
                yield return null;
            }
            if (_releaseGate.TryRelease())
            {
                HideHeldShuriken();
                ReleaseRequested?.Invoke();
            }
            Pose(0f, 0f, 0f);
            IsThrowing = false;
            _routine = null;
            if (_recoverAfterThrow && heldShuriken != null) heldShuriken.SetActive(true);
            _recoverAfterThrow = false;
        }

        private void Pose(float shoulderAngle, float elbowAngle, float wristAngle)
        {
            if (shoulder != null) shoulder.localRotation = _shoulderRest * Quaternion.AngleAxis(shoulderAngle, Vector3.forward);
            if (elbow != null) elbow.localRotation = _elbowRest * Quaternion.AngleAxis(elbowAngle, Vector3.forward);
            if (wrist != null) wrist.localRotation = _wristRest * Quaternion.AngleAxis(wristAngle, Vector3.forward);
        }
    }
}
