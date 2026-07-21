using UnityEngine;

namespace ShinobiZero.Runtime
{
    [RequireComponent(typeof(AudioSource))]
    public sealed class AmbientAudioController : MonoBehaviour
    {
        [SerializeField, Range(0f, 1f)] private float volume = .2f;
        private AudioClip _ambientClip;

        private void Awake()
        {
            var source = GetComponent<AudioSource>();
            source.playOnAwake = false;
            source.loop = true;
            source.spatialBlend = 0f;
            source.volume = volume;
            _ambientClip = BuildRainAndWindLoop();
            source.clip = _ambientClip;
            source.Play();
        }

        private void OnDestroy()
        {
            if (_ambientClip != null) Destroy(_ambientClip);
        }

        private static AudioClip BuildRainAndWindLoop()
        {
            const int sampleRate = 24000;
            const int seconds = 8;
            var samples = new float[sampleRate * seconds];
            var random = new System.Random(1977);
            var wind = 0f;
            var rainImpulse = 0f;
            for (var i = 0; i < samples.Length; i++)
            {
                var noise = (float)random.NextDouble() * 2f - 1f;
                wind = wind * .9985f + noise * .0015f;
                if (random.NextDouble() < .0028) rainImpulse += .18f + (float)random.NextDouble() * .3f;
                rainImpulse *= .965f;
                var distantRain = noise * .045f;
                samples[i] = Mathf.Clamp(wind * .32f + distantRain + noise * rainImpulse, -.72f, .72f);
            }
            var fadeSamples = sampleRate / 3;
            for (var i = 0; i < fadeSamples; i++)
            {
                var amount = i / (float)(fadeSamples - 1);
                amount = amount * amount * (3f - 2f * amount);
                var tail = samples.Length - fadeSamples + i;
                samples[tail] = Mathf.Lerp(samples[tail], samples[i], amount);
            }
            var clip = AudioClip.Create("Temple Rain and Wind", samples.Length, 1, sampleRate, false);
            clip.SetData(samples, 0);
            return clip;
        }
    }
}
