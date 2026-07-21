using System.Collections;
using ShinobiZero.Core;
using UnityEngine;
using UnityEngine.UI;

namespace ShinobiZero.Runtime
{
    public sealed class GameHudController : MonoBehaviour
    {
        [Header("Systems")]
        [SerializeField] private GameFlowController flow;
        [SerializeField] private MatchCoordinator coordinator;
        [SerializeField] private ThrowCalibrationController calibration;
        [SerializeField] private PlayerProgressController progress;
        [SerializeField] private ThrowGestureReader gestureReader;
        [SerializeField] private UiLocalizationController localization;

        [Header("Screens")]
        [SerializeField] private GameObject selectionPanel;
        [SerializeField] private GameObject matchPanel;
        [SerializeField] private GameObject resultPanel;
        [SerializeField] private GameObject calibrationPanel;

        [Header("Selection")]
        [SerializeField] private Button[] opponentButtons;
        [SerializeField] private Text[] opponentLabels;
        [SerializeField] private Button score301Button;
        [SerializeField] private Button score501Button;
        [SerializeField] private Toggle doubleOutToggle;
        [SerializeField] private Button singleLegButton;
        [SerializeField] private Button bestOfThreeButton;
        [SerializeField] private Button startButton;
        [SerializeField] private Button calibrationButton;
        [SerializeField] private Button cancelCalibrationButton;
        [SerializeField] private Text calibrationStatusText;
        [SerializeField] private Text careerText;
        [SerializeField] private Text opponentDetailText;

        [Header("Match")]
        [SerializeField] private Text playerScoreText;
        [SerializeField] private Text enemyScoreText;
        [SerializeField] private Text enemyNameText;
        [SerializeField] private Text turnText;
        [SerializeField] private Text roundText;
        [SerializeField] private Text hitText;
        [SerializeField] private Text checkoutText;
        [SerializeField] private Text legsText;
        [SerializeField] private Text turnSummaryText;

        [Header("Result")]
        [SerializeField] private Text resultTitleText;
        [SerializeField] private Text resultDetailText;
        [SerializeField] private Button rematchButton;
        [SerializeField] private Button changeOpponentButton;

        private readonly Color _selected = new Color(.48f, .09f, .07f, .96f);
        private readonly Color _normal = new Color(.055f, .07f, .075f, .92f);
        private readonly TurnHistoryTracker _turnHistory = new TurnHistoryTracker();
        private TutorialInputMode _inputMode;
        private bool _showingInputPrompt;
        private Coroutine _hitCalloutRoutine;
        private Vector3 _hitTextScale;
        private Color _hitTextColor;
        public bool ReducedMotion { get; set; }

        private void Awake()
        {
            InstallRuntimeFont();
            _hitTextScale = hitText.rectTransform.localScale;
            _hitTextColor = hitText.color;
            for (var i = 0; i < opponentButtons.Length; i++)
            {
                var index = i;
                opponentButtons[i].onClick.AddListener(() => SelectOpponent(index));
                var opponent = flow.GetOpponent(i);
                if (opponent != null && i < opponentLabels.Length) opponentLabels[i].text = opponent.DisplayName;
            }
            score301Button.onClick.AddListener(() => SelectScore(301));
            score501Button.onClick.AddListener(() => SelectScore(501));
            doubleOutToggle.onValueChanged.AddListener(flow.SetDoubleOut);
            singleLegButton.onClick.AddListener(() => SelectFormat(1));
            bestOfThreeButton.onClick.AddListener(() => SelectFormat(2));
            startButton.onClick.AddListener(BeginMatch);
            calibrationButton.onClick.AddListener(BeginCalibration);
            if (calibration.HasSavedCalibration)
                calibrationButton.GetComponentInChildren<Text>().text = English ? "RECALIBRATE" : "投げ方を再調整";
            cancelCalibrationButton.onClick.AddListener(calibration.Cancel);
            rematchButton.onClick.AddListener(BeginMatch);
            changeOpponentButton.onClick.AddListener(ShowSelection);
            SelectOpponent(0);
            SelectScore(301);
            SelectFormat(1);
            RefreshCareer();
            ShowSelection();
        }

        private void Start() => HandleLanguageChanged(Language);

        private void Update()
        {
            if (!_showingInputPrompt) return;
            var detected = InputModeDetector.Detect(_inputMode);
            if (detected == _inputMode) return;
            _inputMode = detected;
            RenderThrowPrompt();
        }

        private void OnEnable()
        {
            coordinator.ThrowResolved += HandleThrowResolved;
            flow.MatchStarted += HandleMatchStarted;
            coordinator.MatchAborted += ShowSelection;
            calibration.ProgressChanged += HandleCalibrationProgress;
            calibration.Completed += HandleCalibrationCompleted;
            calibration.Cancelled += HandleCalibrationCancelled;
            if (progress != null) progress.StatsChanged += RefreshCareer;
            if (gestureReader != null) gestureReader.Rejected += HandleRejectedThrow;
            if (localization != null) localization.LanguageChanged += HandleLanguageChanged;
        }

        private void OnDisable()
        {
            coordinator.ThrowResolved -= HandleThrowResolved;
            flow.MatchStarted -= HandleMatchStarted;
            coordinator.MatchAborted -= ShowSelection;
            calibration.ProgressChanged -= HandleCalibrationProgress;
            calibration.Completed -= HandleCalibrationCompleted;
            calibration.Cancelled -= HandleCalibrationCancelled;
            if (progress != null) progress.StatsChanged -= RefreshCareer;
            if (gestureReader != null) gestureReader.Rejected -= HandleRejectedThrow;
            if (localization != null) localization.LanguageChanged -= HandleLanguageChanged;
            ResetHitCallout();
        }

        private void SelectOpponent(int index)
        {
            flow.SelectOpponent(index);
            for (var i = 0; i < opponentButtons.Length; i++) SetButtonColor(opponentButtons[i], i == index);
            var opponent = flow.CurrentOpponent;
            if (opponentDetailText != null && opponent != null)
            {
                var identity = English
                    ? opponent.EnglishTitle + " · " + OpponentStrategyNames.English(opponent.Strategy) + "  |  DIFFICULTY "
                        + OpponentDifficultyModel.Stars(opponent.Skill) + "  |  " + opponent.EnglishStyleDescription
                    : opponent.Title + "・" + OpponentStrategyNames.Japanese(opponent.Strategy) + "　｜　難易度 "
                        + OpponentDifficultyModel.Stars(opponent.Skill) + "　｜　" + opponent.StyleDescription;
                var starter = flow.NextStarter == Combatant.Player
                    ? (English ? "YOU" : "あなた") : OpponentName(opponent);
                opponentDetailText.text = identity + (English ? "\nFIRST THROW  " : "\n先攻　") + starter;
            }
        }

        private void SelectScore(int score)
        {
            flow.SetStartScore(score);
            SetButtonColor(score301Button, score == 301);
            SetButtonColor(score501Button, score == 501);
        }

        private void SelectFormat(int legsToWin)
        {
            flow.SetLegsToWin(legsToWin);
            SetButtonColor(singleLegButton, legsToWin == 1);
            SetButtonColor(bestOfThreeButton, legsToWin == 2);
        }

        private void BeginMatch()
        {
            resultPanel.SetActive(false);
            selectionPanel.SetActive(false);
            matchPanel.SetActive(true);
            _turnHistory.Reset();
            flow.BeginMatch();
            if (coordinator.Match.Turn == Combatant.Player) ShowThrowPrompt();
            else ShowRivalOpening();
        }

        private void HandleMatchStarted()
        {
            resultPanel.SetActive(false);
            selectionPanel.SetActive(false);
            matchPanel.SetActive(true);
            _turnHistory.Reset();
            RenderMatch();
            if (flow.LastMatchWasResumed)
            {
                hitText.text = English ? "MATCH RESTORED" : "対戦を復帰しました";
                _showingInputPrompt = false;
            }
            else if (coordinator.Match.Turn == Combatant.Player) ShowThrowPrompt();
            else ShowRivalOpening();
        }

        private void BeginCalibration()
        {
            calibrationPanel.SetActive(true);
            calibration.Begin();
        }

        private void HandleCalibrationProgress(int completed, int required)
        {
            calibrationStatusText.text = completed == 0
                ? (English ? "MAKE 3 NATURAL UPWARD THROWS" : "自然な速さで上へ3回払う")
                : completed + " / " + required + (English ? "  RECORDED" : "　記録済み");
        }

        private void HandleCalibrationCompleted(float idealRise)
        {
            calibrationStatusText.text = (English ? "CALIBRATED  BASELINE " : "調整完了　基準 ") + Mathf.RoundToInt(idealRise * 100f) + "%";
            calibrationButton.GetComponentInChildren<Text>().text = English ? "RECALIBRATE" : "投げ方を再調整";
            calibrationPanel.SetActive(false);
        }

        private void HandleCalibrationCancelled() => calibrationPanel.SetActive(false);

        private void HandleRejectedThrow(ThrowRejectionReason reason)
        {
            var match = coordinator.Match;
            if (!match.HasStarted || match.IsFinished || coordinator.IsPaused || match.Turn != Combatant.Player) return;
            _showingInputPrompt = false;
            if (reason == ThrowRejectionReason.WrongDirection) hitText.text = English ? "SWIPE UPWARD" : "上へ払ってください";
            else if (reason == ThrowRejectionReason.TooShort) hitText.text = English ? "MAKE A LONGER THROW" : "もう少し大きく払う";
            else if (reason == ThrowRejectionReason.TooSlow) hitText.text = English ? "THROW FASTER" : "もう少し速く払う";
            else if (reason == ThrowRejectionReason.TooLong) hitText.text = English ? "THROW IN ONE MOTION" : "一息で投げる";
        }

        private void RefreshCareer()
        {
            if (progress == null || progress.Stats == null || careerText == null) return;
            var stats = progress.Stats;
            var rank = CareerRankModel.Evaluate(stats);
            var rankLine = English
                ? "RANK  " + CareerRankModel.English(rank.Rank) + (rank.IsMaximum ? "  ·  MASTERED" : "  ·  NEXT " + rank.NextWins + "W / " + rank.NextOpponents + " RIVALS")
                : "階級 " + CareerRankModel.Japanese(rank.Rank) + (rank.IsMaximum ? "・極" : "　次 " + rank.NextWins + "勝・" + rank.NextOpponents + "人撃破");
            careerText.text = rankLine + "\n" + (English
                ? "CAREER  " + stats.Wins + "W " + stats.Losses + "L  HIT " + Mathf.RoundToInt(stats.HitRate * 100f) + "%  BEST OUT " + stats.BestCheckout
                : "戦績 " + stats.Wins + "勝 " + stats.Losses + "敗　命中率 " + Mathf.RoundToInt(stats.HitRate * 100f) + "%　最高上がり " + stats.BestCheckout);
            for (var i = 0; i < opponentLabels.Length; i++)
            {
                var opponent = flow.GetOpponent(i);
                if (opponent == null) continue;
                var wins = stats.OpponentWins != null && i < stats.OpponentWins.Length ? stats.OpponentWins[i] : 0;
                opponentLabels[i].text = OpponentName(opponent) + (English ? "\nWINS " : "\n勝利 ") + wins;
            }
        }

        private void ShowSelection()
        {
            resultPanel.SetActive(false);
            calibrationPanel.SetActive(false);
            matchPanel.SetActive(false);
            selectionPanel.SetActive(true);
            if (flow.OpponentCount > 0) SelectOpponent(flow.SelectedOpponent);
        }

        private void HandleThrowResolved(ThrowOutcome outcome)
        {
            _showingInputPrompt = false;
            _turnHistory.Record(outcome);
            hitText.text = outcome.LegEnded && !outcome.MatchEnded
                ? (outcome.Thrower == Combatant.Player ? (English ? "LEG WON" : "LEG 獲得") : OpponentName(flow.CurrentOpponent) + (English ? "  WINS LEG" : "　LEG獲得"))
                : outcome.Score.Bust
                    ? (outcome.Score.InvalidCheckout ? (English ? "BUST — FINISH ON A DOUBLE" : "BUST — 最後はダブル") : "BUST")
                    : HitLabel(outcome.Hit);
            PlayHitCallout(ImpactFeedbackModel.Evaluate(outcome));
            RenderMatch();
            if (!outcome.MatchEnded)
            {
                if (outcome.TurnEnded && coordinator.Match.Turn == Combatant.Player) ShowThrowPrompt();
                return;
            }
            var playerWon = outcome.Thrower == Combatant.Player;
            resultTitleText.text = playerWon ? (English ? "VICTORY" : "勝利") : (English ? "DEFEAT" : "敗北");
            resultDetailText.text = English
                ? (playerWon ? "You defeated " + OpponentName(flow.CurrentOpponent) + " by reaching zero."
                    : OpponentName(flow.CurrentOpponent) + " reached zero first.")
                : (playerWon ? flow.CurrentOpponent.DisplayName + "を破り、残り得点を零にした。"
                    : flow.CurrentOpponent.DisplayName + "が先に零へ到達した。");
            if (coordinator.Match.Config.LegsToWin > 1)
                resultDetailText.text += "　LEG " + coordinator.Match.PlayerLegs + " - " + coordinator.Match.EnemyLegs;
            var performance = coordinator.PlayerPerformance;
            resultDetailText.text += English
                ? "\n3-DART AVG " + performance.ThreeDartAverage.ToString("0.0") + "  HIT " + Mathf.RoundToInt(performance.HitRate * 100f)
                    + "%  HIGH " + performance.BestTurn + "  CHECKOUT " + performance.BestCheckout
                : "\n3投平均 " + performance.ThreeDartAverage.ToString("0.0") + "　命中率 " + Mathf.RoundToInt(performance.HitRate * 100f)
                    + "%　最高 " + performance.BestTurn + "　上がり " + performance.BestCheckout;
            resultPanel.SetActive(true);
        }

        private void PlayHitCallout(ImpactFeedbackProfile profile)
        {
            ResetHitCallout();
            _hitCalloutRoutine = StartCoroutine(AnimateHitCallout(profile));
        }

        private IEnumerator AnimateHitCallout(ImpactFeedbackProfile profile)
        {
            hitText.color = CalloutColor(profile.Tier);
            hitText.rectTransform.localScale = _hitTextScale * (ReducedMotion ? 1f : profile.CalloutScale);
            var elapsed = 0f;
            while (elapsed < profile.CalloutHoldSeconds)
            {
                elapsed += Time.unscaledDeltaTime;
                yield return null;
            }
            const float settleDuration = .18f;
            elapsed = 0f;
            while (elapsed < settleDuration)
            {
                elapsed += Time.unscaledDeltaTime;
                var t = Mathf.Clamp01(elapsed / settleDuration);
                hitText.color = Color.Lerp(CalloutColor(profile.Tier), _hitTextColor, t);
                if (!ReducedMotion)
                    hitText.rectTransform.localScale = Vector3.Lerp(_hitTextScale * profile.CalloutScale, _hitTextScale, t);
                yield return null;
            }
            ResetHitCallout();
        }

        private void ResetHitCallout()
        {
            if (_hitCalloutRoutine != null) StopCoroutine(_hitCalloutRoutine);
            _hitCalloutRoutine = null;
            if (hitText == null) return;
            hitText.rectTransform.localScale = _hitTextScale;
            hitText.color = _hitTextColor;
        }

        private static Color CalloutColor(ImpactTier tier)
        {
            if (tier == ImpactTier.Bust || tier == ImpactTier.MatchDefeat) return new Color(1f, .24f, .16f);
            if (tier == ImpactTier.Bull || tier == ImpactTier.Checkout || tier == ImpactTier.MatchVictory) return new Color(1f, .78f, .26f);
            if (tier == ImpactTier.Triple || tier == ImpactTier.Double) return new Color(1f, .48f, .2f);
            if (tier == ImpactTier.Miss) return new Color(.55f, .58f, .6f);
            return Color.white;
        }

        private void RenderMatch()
        {
            var match = coordinator.Match;
            if (!match.HasStarted) return;
            playerScoreText.text = match.PlayerScore.ToString();
            enemyScoreText.text = match.EnemyScore.ToString();
            enemyNameText.text = flow.CurrentOpponent == null ? "ENEMY" : OpponentName(flow.CurrentOpponent);
            roundText.text = "ROUND " + match.Round;
            legsText.text = match.Config.LegsToWin == 1
                ? "LEG 1"
                : "LEG " + match.LegNumber + "　" + match.PlayerLegs + " - " + match.EnemyLegs;
            turnText.text = match.Turn == Combatant.Player
                ? (English ? "YOUR TURN  " + match.DartsLeft + " THROWS" : "あなたの番　残り" + match.DartsLeft + "投")
                : (English ? "RIVAL TURN  " + match.DartsLeft + " THROWS" : "敵の番　残り" + match.DartsLeft + "投");
            RenderTurnSummary();
            if (match.Turn != Combatant.Player)
            {
                checkoutText.text = string.Empty;
                return;
            }

            var route = CheckoutAdvisor.Find(match.PlayerScore, match.DartsLeft, match.Config.DoubleOut);
            checkoutText.text = route.IsPossible
                ? (English ? "ROUTE  " : "狙い　") + CheckoutAdvisor.Format(route)
                : (match.Config.DoubleOut && match.PlayerScore <= 170 ? (English ? "NO CHECKOUT WITH THESE DARTS" : "この投数では上がれない") : string.Empty);
        }

        private void RenderTurnSummary()
        {
            if (turnSummaryText == null || _turnHistory.Count == 0)
            {
                if (turnSummaryText != null) turnSummaryText.text = string.Empty;
                return;
            }
            var text = English
                ? (_turnHistory.Thrower == Combatant.Player ? "YOU  " : OpponentName(flow.CurrentOpponent) + "  ")
                : (_turnHistory.Thrower == Combatant.Player ? "あなた　" : OpponentName(flow.CurrentOpponent) + "　");
            for (var i = 0; i < _turnHistory.Count; i++)
            {
                if (i > 0) text += English ? " · " : "・";
                text += CompactHit(_turnHistory.HitAt(i));
            }
            text += _turnHistory.Bust ? "  BUST" : (English ? "  = " : "　計") + _turnHistory.Total;
            turnSummaryText.text = text;
        }

        private static string CompactHit(DartHit hit)
        {
            if (hit.Score == 0) return "MISS";
            if (hit.Base == 25) return hit.Multiplier == 2 ? "BULL" : "25";
            if (hit.Multiplier == 3) return "T" + hit.Base;
            if (hit.Multiplier == 2) return "D" + hit.Base;
            return hit.Base.ToString();
        }

        private string HitLabel(DartHit hit)
        {
            if (hit.Score == 0) return "MISS";
            if (hit.Base == 25) return hit.Multiplier == 2 ? "BULL — 50" : "OUTER BULL — 25";
            if (hit.Multiplier == 3) return "TRIPLE " + hit.Base + " — " + hit.Score;
            if (hit.Multiplier == 2) return "DOUBLE " + hit.Base + " — " + hit.Score;
            return hit.Score + (English ? " POINTS" : "点");
        }

        private GameLanguage Language { get { return localization == null ? GameLanguage.Japanese : localization.Language; } }
        private bool English { get { return Language == GameLanguage.English; } }
        private string OpponentName(OpponentProfile opponent) { return opponent == null ? "ENEMY" : (English ? opponent.EnglishDisplayName : opponent.DisplayName); }

        private void HandleLanguageChanged(GameLanguage language)
        {
            RefreshCareer();
            SelectOpponent(flow.SelectedOpponent);
            if (calibration.HasSavedCalibration)
                calibrationButton.GetComponentInChildren<Text>().text = language == GameLanguage.English ? "RECALIBRATE" : "投げ方を再調整";
            if (coordinator.Match.HasStarted && !coordinator.Match.IsFinished) RenderMatch();
            RenderTurnSummary();
            if (_showingInputPrompt) RenderThrowPrompt();
        }

        private void ShowThrowPrompt()
        {
            _inputMode = InputModeDetector.Detect(InputModeDetector.Default());
            _showingInputPrompt = true;
            RenderThrowPrompt();
        }

        private void RenderThrowPrompt() => hitText.text = ThrowPromptCatalog.Text(_inputMode, Language);

        private void ShowRivalOpening()
        {
            _showingInputPrompt = false;
            hitText.text = English ? "RIVAL PREPARES TO THROW" : "敵が投擲の構えに入る";
        }

        private void SetButtonColor(Button button, bool selected)
        {
            var colors = button.colors;
            colors.normalColor = selected ? _selected : _normal;
            colors.selectedColor = colors.normalColor;
            button.colors = colors;
        }

        private void InstallRuntimeFont()
        {
            var font = Font.CreateDynamicFontFromOSFont(
                new[] { "Yu Gothic UI", "Hiragino Sans", "Noto Sans CJK JP", "Meiryo", "Arial" }, 32);
            if (font == null) return;
            foreach (var text in GetComponentsInChildren<Text>(true)) text.font = font;
        }
    }
}
