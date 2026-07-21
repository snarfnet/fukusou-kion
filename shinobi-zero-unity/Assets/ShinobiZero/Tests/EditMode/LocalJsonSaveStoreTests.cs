using System;
using System.IO;
using NUnit.Framework;
using ShinobiZero.Runtime;

namespace ShinobiZero.Tests
{
    public sealed class LocalJsonSaveStoreTests
    {
        private string _root;

        [SetUp] public void SetUp() => _root = Path.Combine(Path.GetTempPath(), "ShinobiZeroTests", Guid.NewGuid().ToString("N"));

        [TearDown] public void TearDown()
        {
            if (Directory.Exists(_root)) Directory.Delete(_root, true);
        }

        [Test] public void SaveAndLoadRoundTrip()
        {
            var store = new LocalJsonSaveStore(_root);
            store.Save("career", "{\"Wins\":3}");
            Assert.That(store.TryLoad("career", out var json), Is.True);
            Assert.That(json, Is.EqualTo("{\"Wins\":3}"));
        }

        [Test] public void SecondSavePreservesPreviousGeneration()
        {
            var store = new LocalJsonSaveStore(_root);
            store.Save("career", "first");
            store.Save("career", "second");
            Assert.That(store.TryLoadBackup("career", out var backup), Is.True);
            Assert.That(backup, Is.EqualTo("first"));
        }

        [Test] public void MissingBackupFailsWithoutThrowing()
        {
            var store = new LocalJsonSaveStore(_root);
            Assert.That(store.TryLoadBackup("missing", out var json), Is.False);
            Assert.That(json, Is.Null);
        }

        [Test] public void RecoveryPromotionPreservesGoodBackup()
        {
            var store = new LocalJsonSaveStore(_root);
            store.Save("career", "good-generation");
            store.Save("career", "corrupt-primary");
            Assert.That(store.TryLoadBackup("career", out var backup), Is.True);
            Assert.That(backup, Is.EqualTo("good-generation"));

            store.SaveRecovered("career", backup);

            Assert.That(store.TryLoad("career", out var primary), Is.True);
            Assert.That(primary, Is.EqualTo("good-generation"));
            Assert.That(store.TryLoadBackup("career", out var preserved), Is.True);
            Assert.That(preserved, Is.EqualTo("good-generation"));
        }

        [Test] public void DeleteRemovesPrimaryAndBackup()
        {
            var store = new LocalJsonSaveStore(_root);
            store.Save("active", "first");
            store.Save("active", "second");
            store.Delete("active");
            Assert.That(store.TryLoad("active", out _), Is.False);
            Assert.That(store.TryLoadBackup("active", out _), Is.False);
        }
    }
}
