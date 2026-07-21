using UnityEngine;

namespace ShinobiZero.Runtime
{
    [CreateAssetMenu(menuName = "SHINOBI ZERO/Throw Animation Profile")]
    public sealed class ThrowAnimationProfile : ScriptableObject
    {
        [SerializeField] private string stateName = "Throw";
        [SerializeField, Range(0f, 1f)] private float releaseNormalizedTime = .64f;
        [SerializeField, Range(0f, .3f)] private float crossFadeDuration = .08f;
        [SerializeField, Range(0f, 20f)] private float shoulderAimLimit = 6f;
        [SerializeField, Range(0f, 20f)] private float wristAimLimit = 9f;
        [SerializeField, Range(.25f, 1.5f)] private float throwDuration = .72f;
        [SerializeField, Range(15f, 90f)] private float windupDegrees = 52f;
        [SerializeField, Range(20f, 110f)] private float followThroughDegrees = 68f;

        public string StateName { get { return stateName; } }
        public float ReleaseNormalizedTime { get { return releaseNormalizedTime; } }
        public float CrossFadeDuration { get { return crossFadeDuration; } }
        public float ShoulderAimLimit { get { return shoulderAimLimit; } }
        public float WristAimLimit { get { return wristAimLimit; } }
        public float ThrowDuration { get { return throwDuration; } }
        public float WindupDegrees { get { return windupDegrees; } }
        public float FollowThroughDegrees { get { return followThroughDegrees; } }
    }
}
