using System;
using System.IO;
using NUnit.Framework;
using ShinobiZero.Runtime;

namespace ShinobiZero.Tests
{
    public sealed class PlatformServicesTests
    {
        private string _root;

        [SetUp] public void SetUp() => _root = Path.Combine(Path.GetTempPath(), "ShinobiZeroCloudTests", Guid.NewGuid().ToString("N"));
        [TearDown] public void TearDown() { if (Directory.Exists(_root)) Directory.Delete(_root, true); }

        [Test] public void CloudSaveSurvivesAServiceRestart()
        {
            var expected = System.Text.Encoding.UTF8.GetBytes("{\"Revision\":7}");
            new LocalPlatformServices(_root).SaveCloud(expected);
            Assert.That(new LocalPlatformServices(_root).TryLoadCloud(out var actual), Is.True);
            Assert.That(actual, Is.EqualTo(expected));
        }

        [Test] public void SecondCloudSavePreservesPreviousGeneration()
        {
            var services = new LocalPlatformServices(_root);
            services.SaveCloud(new byte[] { 1, 2, 3 });
            services.SaveCloud(new byte[] { 4, 5, 6 });
            Assert.That(File.ReadAllBytes(Path.Combine(_root, "career-cloud.json.bak")), Is.EqualTo(new byte[] { 1, 2, 3 }));
        }

        [Test] public void OversizedCloudSaveIsRejected()
        {
            Assert.Throws<ArgumentException>(() => new LocalPlatformServices(_root).SaveCloud(new byte[1024 * 1024 + 1]));
        }
    }
}
