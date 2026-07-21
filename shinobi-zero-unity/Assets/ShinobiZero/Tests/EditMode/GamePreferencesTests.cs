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
        }

        [TestCase(true, true, false, false, true)]
        [TestCase(false, true, true, false, false)]
        [TestCase(true, false, true, true, false)]
        [TestCase(false, false, false, true, true)]
        public void RoundTrips(bool sound, bool haptics, bool reducedMotion, bool english, bool fullscreen)
        {
            var decoded = PreferencesCodec.Decode(PreferencesCodec.Encode(new GamePreferences(sound, haptics, reducedMotion, english, fullscreen)));
            Assert.That(decoded.SoundEnabled, Is.EqualTo(sound));
            Assert.That(decoded.HapticsEnabled, Is.EqualTo(haptics));
            Assert.That(decoded.ReducedMotion, Is.EqualTo(reducedMotion));
            Assert.That(decoded.EnglishUi, Is.EqualTo(english));
            Assert.That(decoded.Fullscreen, Is.EqualTo(fullscreen));
        }

        [Test] public void LegacyPreferencesDefaultToFullscreen()
        {
            var decoded = PreferencesCodec.Decode((1 << 8) | 1 | 2 | 8);
            Assert.That(decoded.SoundEnabled, Is.True);
            Assert.That(decoded.HapticsEnabled, Is.True);
            Assert.That(decoded.EnglishUi, Is.True);
            Assert.That(decoded.Fullscreen, Is.True);
        }
    }
}
