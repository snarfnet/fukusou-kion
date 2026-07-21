using System.Collections;
using ShinobiZero.Core;
using UnityEngine;

namespace ShinobiZero.Runtime
{
    [RequireComponent(typeof(AudioSource))]
    public sealed class ThrowFeedbackController : MonoBehaviour
    {
        [SerializeField] private MatchCoordinator coordinator;
        [SerializeField] private Camera gameCamera;
        [SerializeField, Range(0f, .15f)] private float cameraKick = .035f;

        private AudioSource _audio;
        private AudioClip _throwClip;
        private AudioClip _woodClip;
        private AudioClip _metalClip;
        private AudioClip _missClip;
        private AudioClip _victoryClip;
        private AudioClip _defeatClip;
        private Vector3 _cameraOrigin;
        private float _cameraFov;
        private Coroutine _cameraRoutine;
        private ParticleSystem _sparks;
        private Material _sparkMaterial;
        private bool _initialized;
        private bool _reducedMotion;
        public bool ReducedMotion
        {
            get { return _reducedMotion; }
            set
            {
                _reducedMotion = value;
                if (!value || gameCamera == null || !_initialized) return;
                if (_cameraRoutine != null) StopCoroutine(_cameraRoutine);
                _cameraRoutine = null;
                gameCamera.transform.localPosition = _cameraOrigin;
                gameCamera.fieldOfView = _cameraFov;
            }
        }

        private void Awake()
        {
            _audio = GetComponent<AudioSource>();
            _audio.playOnAwake = false;
            _audio.spatialBlend = 0f;
            _throwClip = MakeNoiseClip("Shuriken Air", .16f, 380f, 1180f, .28f, 17);
            _woodClip = MakeNoiseClip("Wood Impact", .13f, 155f, 72f, .58f, 29);
            _metalClip = MakeNoiseClip("Ring Impact", .2f, 940f, 510f, .42f, 41);
            _missClip = MakeNoiseClip("Miss", .18f, 260f, 90f, .16f, 53);
            _victoryClip = MakeNoiseClip("Victory Steel", .42f, 220f, 920f, .18f, 67);
            _defeatClip = MakeNoiseClip("Defeat Steel", .34f, 310f, 82f, .25f, 71);
            CreateImpactSparks();
            if (gameCamera != null)
            {
                _cameraOrigin = gameCamera.transform.localPosition;
                _cameraFov = gameCamera.fieldOfView;
            }
            _initialized = true;
        }

        private void OnEnable()
        {
            if (coordinator == null) return;
            coordinator.ThrowLaunched += HandleLaunched;
            coordinator.ThrowImpactResolved += HandleResolved;
        }

        private void OnDisable()
        {
            if (coordinator != null)
            {
                coordinator.ThrowLaunched -= HandleLaunched;
                coordinator.ThrowImpactResolved -= HandleResolved;
            }
            if (_cameraRoutine != null) StopCoroutine(_cameraRoutine);
            _cameraRoutine = null;
            if (gameCamera != null && _initialized)
            {
                gameCamera.transform.localPosition = _cameraOrigin;
                gameCamera.fieldOfView = _cameraFov;
            }
        }

        private void OnDestroy()
        {
            if (_sparkMaterial != null) Destroy(_sparkMaterial);
        }

        private void HandleLaunched(float power, float spin)
        {
            _audio.pitch = Mathf.Lerp(.86f, 1.18f, Mathf.Clamp01(power)) + Mathf.Clamp(spin / 9000f, -.08f, .08f);
            _audio.PlayOneShot(_throwClip, Mathf.Lerp(.35f, .62f, Mathf.Clamp01(power)));
        }

        private void HandleResolved(ThrowOutcome outcome, Vector3 worldPoint, bool hasWorldPoint)
        {
            var profile = ImpactFeedbackModel.Evaluate(outcome);
            if (profile.Tier == ImpactTier.Miss)
            {
                _audio.pitch = .9f;
                _audio.PlayOneShot(_missClip, .38f);
                return;
            }

            if (profile.Tier == ImpactTier.MatchVictory)
            {
                _audio.pitch = 1f;
                _audio.PlayOneShot(_victoryClip, .9f);
            }
            else if (profile.Tier == ImpactTier.MatchDefeat || profile.Tier == ImpactTier.Bust)
            {
                _audio.pitch = profile.Tier == ImpactTier.Bust ? .82f : .72f;
                _audio.PlayOneShot(profile.Tier == ImpactTier.Bust ? _woodClip : _defeatClip, .7f);
            }
            else
            {
                var premium = profile.Tier != ImpactTier.Standard;
                _audio.pitch = premium ? 1.08f : Random.Range(.92f, 1.03f);
                _audio.PlayOneShot(premium ? _metalClip : _woodClip, premium ? .78f : .62f);
            }

            if (hasWorldPoint && profile.SparkCount > 0) EmitSparks(worldPoint, profile);
            if (outcome.Thrower == Combatant.Player)
            {
                if (profile.Tier == ImpactTier.MatchVictory || profile.Tier == ImpactTier.Checkout) HapticFeedback.Success();
                else if (profile.Tier == ImpactTier.Bust) HapticFeedback.Error();
                else if (profile.Tier != ImpactTier.Standard) HapticFeedback.MediumImpact();
            }
            if (gameCamera == null || ReducedMotion) return;
            if (_cameraRoutine != null) StopCoroutine(_cameraRoutine);
            _cameraRoutine = StartCoroutine(KickCamera(profile.CameraStrength, profile.ZoomDegrees));
        }

        private IEnumerator KickCamera(float strength, float zoomDegrees)
        {
            var duration = zoomDegrees > 0f ? .26f : .13f;
            var elapsed = 0f;
            while (elapsed < duration)
            {
                elapsed += Time.unscaledDeltaTime;
                var fade = 1f - Mathf.Clamp01(elapsed / duration);
                var offset = Random.insideUnitCircle * cameraKick * strength * fade;
                gameCamera.transform.localPosition = _cameraOrigin + new Vector3(offset.x, offset.y, 0f);
                gameCamera.fieldOfView = _cameraFov - Mathf.Sin(Mathf.Clamp01(elapsed / duration) * Mathf.PI) * zoomDegrees;
                yield return null;
            }
            gameCamera.transform.localPosition = _cameraOrigin;
            gameCamera.fieldOfView = _cameraFov;
            _cameraRoutine = null;
        }

        private void CreateImpactSparks()
        {
            var sparkObject = new GameObject("Impact Sparks", typeof(ParticleSystem));
            sparkObject.transform.SetParent(transform, false);
            _sparks = sparkObject.GetComponent<ParticleSystem>();
            var main = _sparks.main;
            main.loop = false;
            main.playOnAwake = false;
            main.simulationSpace = ParticleSystemSimulationSpace.World;
            main.startLifetime = new ParticleSystem.MinMaxCurve(.12f, .28f);
            main.startSpeed = new ParticleSystem.MinMaxCurve(1.2f, 3.4f);
            main.startSize = new ParticleSystem.MinMaxCurve(.008f, .025f);
            main.maxParticles = 64;
            var emission = _sparks.emission;
            emission.enabled = false;
            var renderer = _sparks.GetComponent<ParticleSystemRenderer>();
            renderer.renderMode = ParticleSystemRenderMode.Stretch;
            renderer.lengthScale = 2.2f;
            var shader = Shader.Find("Particles/Standard Unlit") ?? Shader.Find("Universal Render Pipeline/Particles/Unlit") ?? Shader.Find("Unlit/Color");
            if (shader != null)
            {
                _sparkMaterial = new Material(shader) { color = new Color(1f, .58f, .2f, .9f) };
                renderer.sharedMaterial = _sparkMaterial;
            }
        }

        private void EmitSparks(Vector3 worldPoint, ImpactFeedbackProfile profile)
        {
            var emit = new ParticleSystem.EmitParams
            {
                position = worldPoint - Vector3.forward * .03f,
                applyShapeToPosition = false,
                startColor = profile.Tier == ImpactTier.Bull || profile.Tier == ImpactTier.MatchVictory
                    ? new Color(1f, .82f, .38f, 1f)
                    : new Color(1f, .43f, .16f, .92f)
            };
            _sparks.Emit(emit, profile.SparkCount);
        }

        private static AudioClip MakeNoiseClip(string name, float duration, float startFrequency, float endFrequency, float noise, int seed)
        {
            const int sampleRate = 24000;
            var count = Mathf.CeilToInt(duration * sampleRate);
            var samples = new float[count];
            var random = new System.Random(seed);
            var phase = 0f;
            for (var i = 0; i < count; i++)
            {
                var t = i / (float)count;
                var frequency = Mathf.Lerp(startFrequency, endFrequency, t);
                phase += frequency / sampleRate * Mathf.PI * 2f;
                var envelope = Mathf.Pow(1f - t, 2.4f);
                var grit = ((float)random.NextDouble() * 2f - 1f) * noise;
                samples[i] = (Mathf.Sin(phase) * (1f - noise) + grit) * envelope;
            }
            var clip = AudioClip.Create(name, count, 1, sampleRate, false);
            clip.SetData(samples, 0);
            return clip;
        }
    }
}
