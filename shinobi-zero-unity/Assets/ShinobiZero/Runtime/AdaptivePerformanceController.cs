using ShinobiZero.Core;
using UnityEngine;

namespace ShinobiZero.Runtime
{
    public sealed class AdaptivePerformanceController : MonoBehaviour
    {
        [SerializeField] private ParticleSystem rain;
        [SerializeField] private Light keyLight;

        public RuntimeQualityTier CurrentTier { get { return _governor == null ? RuntimeQualityTier.High : _governor.Tier; } }

        private PerformanceGovernor _governor;
        private float _elapsed;
        private int _frames;
        private bool _focused = true;
        private bool _suspended;

        private void Awake()
        {
            var initial = PerformanceGovernor.InitialTier(
                SystemInfo.systemMemorySize, SystemInfo.graphicsMemorySize, Application.isMobilePlatform);
            _governor = new PerformanceGovernor(initial);
            Apply(initial);
        }

        private void OnEnable() => Application.lowMemory += HandleLowMemory;
        private void OnDisable() => Application.lowMemory -= HandleLowMemory;

        private void HandleLowMemory()
        {
            ResetWindow();
            if (_governor != null && _governor.HandleMemoryPressure()) Apply(_governor.Tier);
        }

        private void Update()
        {
            if (!_focused || _suspended || Time.timeScale <= 0f || Time.unscaledDeltaTime <= 0f || Time.unscaledDeltaTime > .1f) return;
            _elapsed += Time.unscaledDeltaTime;
            _frames++;
            if (_elapsed < 1f || _frames == 0) return;
            var averageMilliseconds = _elapsed * 1000f / _frames;
            _elapsed = 0f;
            _frames = 0;
            if (_governor.Sample(averageMilliseconds)) Apply(_governor.Tier);
        }

        private void OnApplicationFocus(bool focused)
        {
            _focused = focused;
            ResetWindow();
        }

        private void OnApplicationPause(bool suspended)
        {
            _suspended = suspended;
            ResetWindow();
        }

        private void ResetWindow()
        {
            _elapsed = 0f;
            _frames = 0;
        }

        private void Apply(RuntimeQualityTier tier)
        {
            if (rain != null)
            {
                var main = rain.main;
                var emission = rain.emission;
                if (tier == RuntimeQualityTier.High)
                {
                    main.maxParticles = 520;
                    emission.rateOverTime = 190f;
                }
                else if (tier == RuntimeQualityTier.Balanced)
                {
                    main.maxParticles = 320;
                    emission.rateOverTime = 110f;
                }
                else
                {
                    main.maxParticles = 160;
                    emission.rateOverTime = 55f;
                }
            }
            if (keyLight != null)
                keyLight.shadows = tier == RuntimeQualityTier.High ? LightShadows.Soft
                    : tier == RuntimeQualityTier.Balanced ? LightShadows.Hard : LightShadows.None;
            QualitySettings.shadowDistance = tier == RuntimeQualityTier.High ? 30f : tier == RuntimeQualityTier.Balanced ? 18f : 0f;
            QualitySettings.antiAliasing = tier == RuntimeQualityTier.High ? 2 : 0;
            QualitySettings.lodBias = tier == RuntimeQualityTier.Performance ? .7f : tier == RuntimeQualityTier.Balanced ? .85f : 1f;
            RenderSettings.fogDensity = tier == RuntimeQualityTier.High ? .018f
                : tier == RuntimeQualityTier.Balanced ? .012f : .006f;
        }
    }
}
