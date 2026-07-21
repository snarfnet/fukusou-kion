using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class GamePreferencesTests
    {
        [Test] public void DefaultsArePlayable()
        {
            var value = PreferencesCodec.Decode(0);
            Assert.That(value.SoundEnabled, Is.True);
            Assert.That(value.HapticsEnabled, Is.True);
            Assert.That(value.ReducedMotion, Is.False);
            Assert.That(value.EnglishUi, Is.False);
            Assert.That(value.Fullscreen, Is.True);
            Assert.That(value.VolumeStep, Is.EqualTo(8));
        }

        [TestCase(true, true, false, false, true)]
        [TestCase(false, true, true, false, false)]
        [TestCase(true, false, true, true, false)]
        [TestCase(false, false, false, true, true)]
        public void RoundTrips(bool sound, bool haptics, bool reducedMotion, bool english, bool fullscreen)
        {
            var decoded = PreferencesCodec.Decode(PreferencesCodec.Encode(new GamePreferences(sound, haptics, reducedMotion, english, fullscreen, 6)));
            Assert.That(decoded.SoundEnabled, Is.EqualTo(sound));
            Assert.That(decoded.HapticsEnabled, Is.EqualTo(haptics));
            Assert.That(decoded.ReducedMotion, Is.EqualTo(reducedMotion));
            Assert.That(decoded.EnglishUi, Is.EqualTo(english));
            Assert.That(decoded.Fullscreen, Is.EqualTo(fullscreen));
            Assert.That(decoded.VolumeStep, Is.EqualTo(6));
        }

        [Test] public void LegacyPreferencesDefaultToFullscreen()
        {
            var decoded = PreferencesCodec.Decode((1 << 8) | 1 | 2 | 8);
            Assert.That(decoded.SoundEnabled, Is.True);
            Assert.That(decoded.HapticsEnabled, Is.True);
            Assert.That(decoded.EnglishUi, Is.True);
            Assert.That(decoded.Fullscreen, Is.True);
            Assert.That(decoded.VolumeStep, Is.EqualTo(10));
        }

        [Test] public void PreviousPreferencesKeepTheirFormerFullVolume()
        {
            var decoded = PreferencesCodec.Decode((1 << 9) | 1 | 2 | 16);
            Assert.That(decoded.VolumeStep, Is.EqualTo(10));
        }

        [TestCase(-5, 0)]
        [TestCase(11, 10)]
        public void VolumeStepIsClamped(int requested, int expected) =>
            Assert.That(new GamePreferences(true, true, false, false, true, requested).VolumeStep, Is.EqualTo(expected));
    }
}
