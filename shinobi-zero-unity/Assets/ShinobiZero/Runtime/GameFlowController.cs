using System;
using ShinobiZero.Core;
using UnityEngine;

namespace ShinobiZero.Runtime
{
    public sealed class GameFlowController : MonoBehaviour
    {
        private const string ActiveMatchSlot = "active-match-v1";
        [SerializeField] private MatchCoordinator coordinator;
        [SerializeField] private EnemyTurnDirector enemyDirector;
        [SerializeField] private OpponentProfile[] opponents;
        [SerializeField] private NinjaVisualController ninjaVisual;
        [SerializeField] private NinjaReactionController ninjaReaction;
        [SerializeField] private PlayerProgressController progress;

        public int SelectedOpponent { get; private set; }
        public int StartScore { get; private set; } = 301;
        public bool DoubleOut { get; private set; }
        public int LegsToWin { get; private set; } = 1;
        public Combatant NextStarter { get; private set; } = Combatant.Player;
        public event Action MatchStarted;
        public bool LastMatchWasResumed { get; private set; }

        private ISaveStore _sessionStore;

        private void Awake() => _sessionStore = new LocalJsonSaveStore();
        private void Start() => TryResumeMatch();

        public int OpponentCount { get { return opponents == null ? 0 : opponents.Length; } }

        private void OnEnable()
        {
            if (coordinator != null) coordinator.ThrowResolved += HandleThrowResolved;
        }

        private void OnDisable()
        {
            if (coordinator != null) coordinator.ThrowResolved -= HandleThrowResolved;
        }
        public OpponentProfile CurrentOpponent
        {
            get
            {
                if (OpponentCount == 0) return null;
                return opponents[Mathf.Clamp(SelectedOpponent, 0, opponents.Length - 1)];
            }
        }

        public OpponentProfile GetOpponent(int index)
        {
            return opponents != null && index >= 0 && index < opponents.Length ? opponents[index] : null;
        }

        public void SelectOpponent(int index)
        {
            if (index < 0 || index >= OpponentCount) throw new ArgumentOutOfRangeException("index");
            SelectedOpponent = index;
            if (ninjaVisual != null) ninjaVisual.Configure(CurrentOpponent);
            if (ninjaReaction != null) ninjaReaction.Configure(CurrentOpponent);
        }

        public void SetStartScore(int score)
        {
            if (score != 301 && score != 501) throw new ArgumentOutOfRangeException("score");
            StartScore = score;
        }

        public void SetDoubleOut(bool enabled) => DoubleOut = enabled;

        public void SetLegsToWin(int legsToWin)
        {
            if (legsToWin != 1 && legsToWin != 2) throw new ArgumentOutOfRangeException("legsToWin");
            LegsToWin = legsToWin;
        }

        public void BeginMatch()
        {
            if (CurrentOpponent == null) throw new InvalidOperationException("No opponents configured.");
            enemyDirector.Configure(CurrentOpponent);
            coordinator.StartMatch(StartScore, DoubleOut, LegsToWin, NextStarter);
            LastMatchWasResumed = false;
            MatchStarted?.Invoke();
            enemyDirector.BeginTurnIfNeeded(.35f);
            SaveCheckpoint(progress == null ? null : progress.Stats);
        }

        private void HandleThrowResolved(ThrowOutcome outcome)
        {
            if (!outcome.MatchEnded) return;
            NextStarter = MatchOrder.Opponent(NextStarter);
            ClearCheckpoint();
        }

        public void AbortMatch()
        {
            enemyDirector.CancelPendingThrow();
            coordinator.AbortMatch();
            ClearCheckpoint();
        }

        public void SaveCheckpoint(CareerStats career)
        {
            if (career == null || !coordinator.Match.HasStarted || coordinator.Match.IsFinished) return;
            var save = new ActiveMatchSave
            {
                Opponent = SelectedOpponent,
                NextStarter = (int)NextStarter,
                Match = coordinator.Match.Capture(),
                Performance = coordinator.CapturePerformance(),
                Career = career
            };
            try { _sessionStore.Save(ActiveMatchSlot, JsonUtility.ToJson(save)); }
            catch (System.IO.IOException) { Debug.LogWarning("SHINOBI ZERO: active match checkpoint failed."); }
            catch (UnauthorizedAccessException) { Debug.LogWarning("SHINOBI ZERO: active match checkpoint access was denied."); }
        }

        private void TryResumeMatch()
        {
            if (TryLoadCheckpoint(false, out var save) && TryApplyCheckpoint(save)) return;
            if (TryLoadCheckpoint(true, out save) && TryApplyCheckpoint(save))
            {
                try { _sessionStore.SaveRecovered(ActiveMatchSlot, JsonUtility.ToJson(save)); }
                catch (System.IO.IOException) { Debug.LogWarning("SHINOBI ZERO: recovered match could not be promoted."); }
                catch (UnauthorizedAccessException) { Debug.LogWarning("SHINOBI ZERO: recovered match promotion was denied."); }
                return;
            }
            ClearCheckpoint();
        }

        private bool TryApplyCheckpoint(ActiveMatchSave save)
        {
            if (save == null || save.Version != 1 || save.Opponent < 0 || save.Opponent >= OpponentCount
                || save.NextStarter < 0 || save.NextStarter > 1 || save.Career == null
                || (progress != null && !CareerSaveResolver.CanRestoreCheckpoint(save.Career, progress.Stats))
                || !coordinator.RestoreMatch(save.Match, save.Performance)) return false;
            SelectedOpponent = save.Opponent;
            NextStarter = (Combatant)save.NextStarter;
            StartScore = save.Match.StartScore;
            DoubleOut = save.Match.DoubleOut;
            LegsToWin = save.Match.LegsToWin;
            SelectOpponent(SelectedOpponent);
            if (progress != null) progress.RestoreCheckpoint(save.Career);
            enemyDirector.Configure(CurrentOpponent);
            LastMatchWasResumed = true;
            MatchStarted?.Invoke();
            enemyDirector.BeginTurnIfNeeded(.35f);
            return true;
        }

        private bool TryLoadCheckpoint(bool backup, out ActiveMatchSave save)
        {
            save = null;
            try
            {
                string json;
                var loaded = backup
                    ? _sessionStore.TryLoadBackup(ActiveMatchSlot, out json)
                    : _sessionStore.TryLoad(ActiveMatchSlot, out json);
                if (!loaded || string.IsNullOrWhiteSpace(json)) return false;
                save = JsonUtility.FromJson<ActiveMatchSave>(json);
                return save != null && save.Version == 1;
            }
            catch (ArgumentException) { return false; }
        }

        private void ClearCheckpoint()
        {
            try { _sessionStore.Delete(ActiveMatchSlot); }
            catch (System.IO.IOException) { Debug.LogWarning("SHINOBI ZERO: active match checkpoint cleanup failed."); }
            catch (UnauthorizedAccessException) { Debug.LogWarning("SHINOBI ZERO: active match checkpoint cleanup was denied."); }
        }
    }
}
