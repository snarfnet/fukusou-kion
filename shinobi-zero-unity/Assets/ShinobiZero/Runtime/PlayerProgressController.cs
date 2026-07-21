using System;
using System.Text;
using ShinobiZero.Core;
using UnityEngine;

namespace ShinobiZero.Runtime
{
    public sealed class PlayerProgressController : MonoBehaviour
    {
        private const string SaveSlot = "career-v1";
        [SerializeField] private MatchCoordinator coordinator;
        [SerializeField] private GameFlowController flow;

        public CareerStats Stats { get; private set; }
        public event Action StatsChanged;
        public event Action<string> AchievementUnlocked;
        public event Action<CareerRank> RankPromoted;

        private ISaveStore _store;
        private CareerTracker _tracker;
        private IPlatformServices _platform;
        private CareerRank _rankAtMatchStart;
        private bool _exitFlushed;

        private void Awake()
        {
            _store = new LocalJsonSaveStore();
            _platform = PlatformServiceRegistry.Create();
            Stats = LoadStats();
            Stats.Normalize(flow == null ? 5 : flow.OpponentCount);
            _tracker = new CareerTracker(Stats);
        }

        private void OnEnable()
        {
            if (flow != null) flow.MatchStarted += HandleMatchStarted;
            if (coordinator != null) coordinator.ThrowResolved += HandleThrowResolved;
            if (coordinator != null) coordinator.MatchAborted += HandleMatchAborted;
        }

        private void OnDisable()
        {
            if (flow != null) flow.MatchStarted -= HandleMatchStarted;
            if (coordinator != null) coordinator.ThrowResolved -= HandleThrowResolved;
            if (coordinator != null) coordinator.MatchAborted -= HandleMatchAborted;
        }

        private void HandleMatchStarted()
        {
            _rankAtMatchStart = CareerRankModel.Evaluate(Stats).Rank;
            _tracker.BeginMatch(flow.SelectedOpponent, flow.OpponentCount);
        }
        private void HandleMatchAborted() => _tracker.AbortMatch();

        private void HandleThrowResolved(ThrowOutcome outcome)
        {
            if (outcome.Thrower == Combatant.Player)
                _tracker.RecordPlayerThrow(outcome.Hit, outcome.Score.Bust, outcome.TurnEnded, outcome.LegEnded, outcome.MatchEnded);
            else if (outcome.MatchEnded)
                _tracker.RecordEnemyWin();
            if (outcome.TurnEnded && !outcome.MatchEnded)
            {
                SaveCareerCheckpoint();
                if (flow != null) flow.SaveCheckpoint(Stats);
            }
            if (!outcome.MatchEnded) return;
            if (Stats.Revision < long.MaxValue) Stats.Revision++;
            Stats.UpdatedUtcTicks = DateTime.UtcNow.Ticks;
            var json = JsonUtility.ToJson(Stats);
            try { _store.Save(SaveSlot, json); }
            catch (System.IO.IOException) { Debug.LogWarning("SHINOBI ZERO: career save failed; current session remains playable."); }
            catch (UnauthorizedAccessException) { Debug.LogWarning("SHINOBI ZERO: career save access was denied."); }
            StatsChanged?.Invoke();
            var currentRank = CareerRankModel.Evaluate(Stats).Rank;
            if (CareerRankModel.IsPromotion(_rankAtMatchStart, currentRank)) RankPromoted?.Invoke(currentRank);
            PublishPlatformProgress(json);
        }

        public void RestoreCheckpoint(CareerStats checkpoint)
        {
            if (checkpoint == null) return;
            checkpoint.Normalize(flow == null ? 5 : flow.OpponentCount);
            Stats = checkpoint;
            _tracker = new CareerTracker(Stats);
            SaveCareerCheckpoint(true);
            StatsChanged?.Invoke();
        }

        public void FlushForExit()
        {
            if (_exitFlushed) return;
            _exitFlushed = true;
            if (coordinator != null && coordinator.Match.HasStarted && !coordinator.Match.IsFinished)
            {
                SaveCareerCheckpoint();
                if (flow != null) flow.SaveCheckpoint(Stats);
            }
            try { if (_platform != null) _platform.Flush(); }
            catch (Exception exception) { Debug.LogWarning("SHINOBI ZERO: final platform flush failed; local save remains available. " + exception.Message); }
            PlayerPrefs.Save();
        }

        private void OnApplicationQuit() => FlushForExit();

        private void SaveCareerCheckpoint(bool recovered = false)
        {
            try
            {
                var json = JsonUtility.ToJson(Stats);
                if (recovered) _store.SaveRecovered(SaveSlot, json);
                else _store.Save(SaveSlot, json);
            }
            catch (System.IO.IOException) { Debug.LogWarning("SHINOBI ZERO: career checkpoint failed."); }
            catch (UnauthorizedAccessException) { Debug.LogWarning("SHINOBI ZERO: career checkpoint access was denied."); }
        }

        private void PublishPlatformProgress(string json)
        {
            try
            {
                var snapshot = PlatformProgressSnapshot.From(Stats);
                for (var i = 0; i < snapshot.Stats.Length; i++)
                    _platform.SetStat(snapshot.Stats[i].Id, snapshot.Stats[i].Value);
                for (var i = 0; i < snapshot.Achievements.Length; i++)
                    if (_platform.UnlockAchievement(snapshot.Achievements[i]))
                        AchievementUnlocked?.Invoke(snapshot.Achievements[i]);
                _platform.SaveCloud(Encoding.UTF8.GetBytes(json));
                _platform.Flush();
            }
            catch (Exception exception)
            {
                Debug.LogWarning("SHINOBI ZERO: platform progress sync failed; local career data is safe. " + exception.Message);
            }
        }

        private CareerStats LoadStats()
        {
            CareerStats local = null;
            var primaryValid = false;
            if (_store.TryLoad(SaveSlot, out var json)) primaryValid = TryDeserialize(json, out local);
            if (local == null && _store.TryLoadBackup(SaveSlot, out json)) TryDeserialize(json, out local);
            var recoveredFromBackup = !primaryValid && local != null;

            CareerStats cloud = null;
            try
            {
                if (_platform.TryLoadCloud(out var bytes) && bytes != null && bytes.Length > 0)
                    TryDeserialize(Encoding.UTF8.GetString(bytes), out cloud);
            }
            catch (Exception exception)
            {
                Debug.LogWarning("SHINOBI ZERO: cloud career load failed; using local data. " + exception.Message);
            }
            var opponentCount = flow == null ? 5 : flow.OpponentCount;
            if (local != null) local.Normalize(opponentCount);
            if (cloud != null) cloud.Normalize(opponentCount);
            var selected = CareerSaveResolver.Choose(local, cloud) ?? new CareerStats();
            if ((!primaryValid || ReferenceEquals(selected, cloud)) && selected != null)
            {
                try
                {
                    var recoveredJson = JsonUtility.ToJson(selected);
                    if (recoveredFromBackup && ReferenceEquals(selected, local)) _store.SaveRecovered(SaveSlot, recoveredJson);
                    else _store.Save(SaveSlot, recoveredJson);
                }
                catch (System.IO.IOException) { Debug.LogWarning("SHINOBI ZERO: recovered career could not be promoted to primary save."); }
                catch (UnauthorizedAccessException) { Debug.LogWarning("SHINOBI ZERO: recovered career promotion was denied."); }
            }
            return selected;
        }

        private static bool TryDeserialize(string json, out CareerStats stats)
        {
            try
            {
                stats = string.IsNullOrWhiteSpace(json) ? null : JsonUtility.FromJson<CareerStats>(json);
                return stats != null;
            }
            catch (ArgumentException) { stats = null; return false; }
        }
    }
}
