using System;
using System.IO;
using UnityEngine;

namespace ShinobiZero.Runtime
{
    public static class PlatformActivityState
    {
        public static bool OverlayActive { get; private set; }
        public static event Action<bool> OverlayChanged;

        public static void SetOverlayActive(bool active)
        {
            if (OverlayActive == active) return;
            OverlayActive = active;
            OverlayChanged?.Invoke(active);
        }

        public static void Reset()
        {
            OverlayActive = false;
            OverlayChanged = null;
        }
    }

    public interface IPlatformServices
    {
        bool UnlockAchievement(string id);
        void SetStat(string id, int value);
        void SaveCloud(byte[] data);
        bool TryLoadCloud(out byte[] data);
        void Flush();
    }

    // A Steamworks or Game Center bootstrap can register its adapter before the scene loads.
    // Gameplay remains independent of either SDK and falls back to local services.
    public static class PlatformServiceRegistry
    {
        private static Func<IPlatformServices> _factory = () => new LocalPlatformServices();

        public static IPlatformServices Create() => _factory();

        public static void Register(Func<IPlatformServices> factory)
        {
            _factory = factory ?? throw new ArgumentNullException("factory");
        }

        public static void Reset() => _factory = () => new LocalPlatformServices();
    }

    public sealed class LocalPlatformServices : IPlatformServices
    {
        private const string AchievementPrefix = "shinobi-zero.achievement.";
        private const string StatPrefix = "shinobi-zero.stat.";

        public bool UnlockAchievement(string id)
        {
            var key = AchievementPrefix + id;
            if (PlayerPrefs.GetInt(key, 0) != 0) return false;
            PlayerPrefs.SetInt(key, 1);
            PlayerPrefs.Save();
            return true;
        }

        public void SetStat(string id, int value) => PlayerPrefs.SetInt(StatPrefix + id, Math.Max(0, value));
        public void SaveCloud(byte[] data) { }
        public bool TryLoadCloud(out byte[] data) { data = null; return false; }
        public void Flush() => PlayerPrefs.Save();
    }

    public interface ISaveStore
    {
        void Save(string slot, string json);
        void SaveRecovered(string slot, string json);
        bool TryLoad(string slot, out string json);
        bool TryLoadBackup(string slot, out string json);
        void Delete(string slot);
    }

    public sealed class LocalJsonSaveStore : ISaveStore
    {
        private readonly string _root;

        public LocalJsonSaveStore(string root = null)
        {
            _root = root ?? Path.Combine(Application.persistentDataPath, "Saves");
        }

        public void Save(string slot, string json)
        {
            Directory.CreateDirectory(_root);
            var finalPath = Path.Combine(_root, SafeSlot(slot) + ".json");
            var temporaryPath = finalPath + ".tmp";
            var backupPath = finalPath + ".bak";
            File.WriteAllText(temporaryPath, json);
            if (File.Exists(finalPath)) File.Copy(finalPath, backupPath, true);
            if (File.Exists(finalPath)) File.Delete(finalPath);
            File.Move(temporaryPath, finalPath);
        }

        public void SaveRecovered(string slot, string json)
        {
            Directory.CreateDirectory(_root);
            var finalPath = Path.Combine(_root, SafeSlot(slot) + ".json");
            var temporaryPath = finalPath + ".tmp";
            File.WriteAllText(temporaryPath, json);
            if (File.Exists(finalPath)) File.Delete(finalPath);
            File.Move(temporaryPath, finalPath);
        }

        public bool TryLoad(string slot, out string json)
        {
            var finalPath = Path.Combine(_root, SafeSlot(slot) + ".json");
            try
            {
                if (File.Exists(finalPath)) { json = File.ReadAllText(finalPath); return true; }
            }
            catch (IOException) { }
            catch (UnauthorizedAccessException) { }
            json = null;
            return false;
        }

        public bool TryLoadBackup(string slot, out string json)
        {
            var backupPath = Path.Combine(_root, SafeSlot(slot) + ".json.bak");
            try
            {
                if (File.Exists(backupPath)) { json = File.ReadAllText(backupPath); return true; }
            }
            catch (IOException) { }
            catch (UnauthorizedAccessException) { }
            json = null;
            return false;
        }

        public void Delete(string slot)
        {
            Directory.CreateDirectory(_root);
            var finalPath = Path.Combine(_root, SafeSlot(slot) + ".json");
            foreach (var path in new[] { finalPath, finalPath + ".tmp", finalPath + ".bak" })
                if (File.Exists(path)) File.Delete(path);
        }

        private static string SafeSlot(string slot)
        {
            foreach (var invalid in Path.GetInvalidFileNameChars()) slot = slot.Replace(invalid, '_');
            return slot;
        }
    }
}
