using System;
using System.Collections.Generic;
using ShinobiZero.Core;
using UnityEngine;

namespace ShinobiZero.Runtime
{
    public sealed class MatchCoordinator : MonoBehaviour
    {
        [Header("Rules")]
        [SerializeField] private int startScore = 301;
        [SerializeField] private bool doubleOut;
        [SerializeField] private bool autoStartWithoutFlow;

        [Header("Input")]
        [SerializeField] private ThrowGestureReader gestureReader;
        [SerializeField] private ThrowMapper throwMapper;
        [SerializeField] private Vector2 aimAnchor;
        [SerializeField] private Camera aimCamera;

        [Header("Throw")]
        [SerializeField] private Transform playerReleasePoint;
        [SerializeField] private Transform enemyReleasePoint;
        [SerializeField] private TargetBoard target;
        [SerializeField] private ShurikenProjectile shurikenPrefab;
        [SerializeField] private NinjaThrowAnimator enemyThrowAnimator;
        [SerializeField] private FirstPersonThrowAnimator playerThrowAnimator;
        [SerializeField, Min(1f)] private float flightSpeed = 16f;
        [SerializeField, Min(0f)] private float openingInputDelay = .4f;

        public MatchEngine Match { get; } = new MatchEngine();
        public bool IsThrowInFlight { get { return _throwInFlight; } }
        public bool IsPaused { get; private set; }
        public event Action<ThrowOutcome> ThrowResolved;
        public event Action<ThrowOutcome, Vector3, bool> ThrowImpactResolved;
        public event Action<float, float> ThrowLaunched;
        public event Action<bool> PausedChanged;
        public event Action MatchAborted;
        public MatchPerformance PlayerPerformance { get { return _performanceTracker.Performance; } }

        private bool _throwInFlight;
        private ThrowIntent? _pendingIntent;
        private ThrowIntent? _pendingPlayerIntent;
        private readonly List<ShurikenProjectile> _embeddedProjectiles = new List<ShurikenProjectile>();
        private Combatant? _projectileOwner;
        private float _nextThrowAllowedAt;
        private readonly MatchPerformanceTracker _performanceTracker = new MatchPerformanceTracker();

        private void Start()
        {
            if (autoStartWithoutFlow) StartMatch(startScore, doubleOut);
        }

        private void OnEnable()
        {
            if (gestureReader != null) gestureReader.Thrown += HandleGesture;
            if (enemyThrowAnimator != null) enemyThrowAnimator.ReleaseRequested += HandleAnimationRelease;
            if (playerThrowAnimator != null) playerThrowAnimator.ReleaseRequested += HandlePlayerAnimationRelease;
        }

        private void OnDisable()
        {
            if (gestureReader != null) gestureReader.Thrown -= HandleGesture;
            if (enemyThrowAnimator != null) enemyThrowAnimator.ReleaseRequested -= HandleAnimationRelease;
            if (playerThrowAnimator != null) playerThrowAnimator.ReleaseRequested -= HandlePlayerAnimationRelease;
        }

        public void StartMatch(int startScore, bool doubleOut, int legsToWin = 1, Combatant startingPlayer = Combatant.Player)
        {
            SetPaused(false);
            ClearEmbeddedProjectiles();
            if (gestureReader != null) gestureReader.CancelTracking();
            Match.Start(new MatchConfig(startScore, doubleOut, legsToWin, startingPlayer));
            _performanceTracker.Reset();
            _nextThrowAllowedAt = Time.unscaledTime + openingInputDelay;
            _pendingPlayerIntent = null;
            if (playerThrowAnimator != null) playerThrowAnimator.SetMatchActive(true);
        }

        public bool RestoreMatch(MatchStateSnapshot match, MatchPerformanceSnapshot performance)
        {
            var validatedPerformance = new MatchPerformanceTracker();
            if (!validatedPerformance.TryRestore(performance) || !Match.TryRestore(match)) return false;
            SetPaused(false);
            ClearEmbeddedProjectiles();
            if (gestureReader != null) gestureReader.CancelTracking();
            _performanceTracker.TryRestore(performance);
            _throwInFlight = false;
            _pendingIntent = null;
            _pendingPlayerIntent = null;
            _nextThrowAllowedAt = Time.unscaledTime + openingInputDelay;
            if (enemyThrowAnimator != null) enemyThrowAnimator.CancelThrow();
            if (playerThrowAnimator != null)
            {
                playerThrowAnimator.SetMatchActive(true);
                if (Match.Turn == Combatant.Player) playerThrowAnimator.RecoverHeldShuriken();
                else playerThrowAnimator.HideHeldShuriken();
            }
            return true;
        }

        public MatchPerformanceSnapshot CapturePerformance() => _performanceTracker.Capture();

        public void SetPaused(bool paused)
        {
            if (IsPaused == paused) return;
            IsPaused = paused;
            PausedChanged?.Invoke(paused);
        }

        public bool AbortMatch()
        {
            if (!Match.Abort()) return false;
            _pendingIntent = null;
            _pendingPlayerIntent = null;
            if (enemyThrowAnimator != null) enemyThrowAnimator.CancelThrow();
            if (playerThrowAnimator != null) playerThrowAnimator.SetMatchActive(false);
            ClearEmbeddedProjectiles();
            _throwInFlight = false;
            SetPaused(false);
            MatchAborted?.Invoke();
            return true;
        }

        private void HandleGesture(ThrowGesture gesture)
        {
            if (IsPaused || _throwInFlight || Time.unscaledTime < _nextThrowAllowedAt || !Match.HasStarted || Match.IsFinished || Match.Turn != Combatant.Player) return;
            var anchor = ResolveAimAnchor(gesture);
            var intent = throwMapper.Map(gesture, anchor);
            TryPlayerThrow(intent.BoardPoint, intent.Power, intent.Spin);
        }

        public bool TryPlayerThrow(Vector2 boardPoint, float power, float spin)
        {
            if (IsPaused || _throwInFlight || _pendingPlayerIntent.HasValue || Time.unscaledTime < _nextThrowAllowedAt
                || !Match.HasStarted || Match.IsFinished || Match.Turn != Combatant.Player) return false;
            var intent = new ThrowIntent(boardPoint, power, spin);
            HapticFeedback.LightImpact();
            if (playerThrowAnimator != null)
            {
                _pendingPlayerIntent = intent;
                if (playerThrowAnimator.PlayThrow(power, spin)) return true;
                _pendingPlayerIntent = null;
            }
            return LaunchAtBoard(boardPoint, power, spin);
        }

        private Vector2 ResolveAimAnchor(ThrowGesture gesture)
        {
            var camera = aimCamera != null ? aimCamera : Camera.main;
            if (camera == null || target == null) return aimAnchor;
            var center = camera.WorldToScreenPoint(target.BoardPointToWorld(Vector2.zero));
            var edge = camera.WorldToScreenPoint(target.BoardPointToWorld(Vector2.right));
            var radius = Vector2.Distance(new Vector2(center.x, center.y), new Vector2(edge.x, edge.y));
            var aim = ScreenAimModel.Map(gesture.End.x, gesture.End.y, center.x, center.y, radius);
            return new Vector2(aim.X, aim.Y);
        }

        private void HandleAnimationRelease()
        {
            if (!_pendingIntent.HasValue) return;
            var intent = _pendingIntent.Value;
            _pendingIntent = null;
            LaunchAtBoard(intent.BoardPoint, intent.Power, intent.Spin);
        }

        private void HandlePlayerAnimationRelease()
        {
            if (!_pendingPlayerIntent.HasValue) return;
            var intent = _pendingPlayerIntent.Value;
            _pendingPlayerIntent = null;
            LaunchAtBoard(intent.BoardPoint, intent.Power, intent.Spin);
        }

        public bool LaunchAtBoard(Vector2 boardPoint, float power, float spin)
        {
            if (IsPaused || _throwInFlight || !Match.HasStarted || Match.IsFinished) return false;
            if (_projectileOwner.HasValue && _projectileOwner.Value != Match.Turn) ClearEmbeddedProjectiles();
            var destination = target.BoardPointToWorld(boardPoint);
            var release = Match.Turn == Combatant.Player ? playerReleasePoint : enemyReleasePoint;
            if (release == null) return false;
            _projectileOwner = Match.Turn;
            var projectile = Instantiate(shurikenPrefab, release.position, release.rotation);
            _embeddedProjectiles.Add(projectile);
            projectile.BoardHit += HandleBoardHit;
            projectile.Missed += HandleMiss;
            var speed = flightSpeed * Mathf.Lerp(.82f, 1.1f, power);
            var origin = release.position;
            var solution = BallisticSolver.SolveLowArc(
                origin.x, origin.y, origin.z, destination.x, destination.y, destination.z,
                speed, Mathf.Abs(Physics.gravity.y));
            var velocity = solution.Reachable
                ? new Vector3(solution.VelocityX, solution.VelocityY, solution.VelocityZ)
                : (destination - origin).normalized * speed;
            projectile.Launch(velocity, spin);
            _throwInFlight = true;
            ThrowLaunched?.Invoke(power, spin);
            return true;
        }

        public bool AnimateLaunchAtBoard(Vector2 boardPoint, float power, float spin, ThrowAnimationProfile profile)
        {
            if (enemyThrowAnimator == null) return LaunchAtBoard(boardPoint, power, spin);
            if (IsPaused || _throwInFlight || _pendingIntent.HasValue || !Match.HasStarted || Match.IsFinished) return false;
            _pendingIntent = new ThrowIntent(boardPoint, power, spin);
            if (enemyThrowAnimator.PlayThrow(profile)) return true;
            _pendingIntent = null;
            return false;
        }

        private void HandleBoardHit(ShurikenProjectile projectile, TargetBoard board, Vector3 worldPoint)
        {
            projectile.BoardHit -= HandleBoardHit;
            projectile.Missed -= HandleMiss;
            _throwInFlight = false;
            var outcome = Match.Submit(board.ScoreWorldPoint(worldPoint));
            if (outcome.Thrower == Combatant.Player)
                _performanceTracker.Record(outcome.Hit, outcome.Score.Bust, outcome.TurnEnded, outcome.LegEnded);
            if (outcome.LegEnded && !outcome.MatchEnded) _nextThrowAllowedAt = Time.unscaledTime + 1.35f;
            ThrowImpactResolved?.Invoke(outcome, worldPoint, true);
            ThrowResolved?.Invoke(outcome);
            UpdatePlayerHand(outcome);
        }

        private void HandleMiss(ShurikenProjectile projectile)
        {
            projectile.BoardHit -= HandleBoardHit;
            projectile.Missed -= HandleMiss;
            _embeddedProjectiles.Remove(projectile);
            _throwInFlight = false;
            var outcome = Match.Submit(DartHit.Miss);
            if (outcome.Thrower == Combatant.Player)
                _performanceTracker.Record(outcome.Hit, outcome.Score.Bust, outcome.TurnEnded, outcome.LegEnded);
            ThrowImpactResolved?.Invoke(outcome, Vector3.zero, false);
            ThrowResolved?.Invoke(outcome);
            UpdatePlayerHand(outcome);
        }

        private void UpdatePlayerHand(ThrowOutcome outcome)
        {
            if (playerThrowAnimator == null) return;
            if (outcome.MatchEnded) playerThrowAnimator.SetMatchActive(false);
            else if (Match.Turn == Combatant.Player) playerThrowAnimator.RecoverHeldShuriken();
            else playerThrowAnimator.HideHeldShuriken();
        }

        private void ClearEmbeddedProjectiles()
        {
            for (var i = 0; i < _embeddedProjectiles.Count; i++)
                if (_embeddedProjectiles[i] != null) _embeddedProjectiles[i].Cancel();
            _embeddedProjectiles.Clear();
            _projectileOwner = null;
        }
    }
}
