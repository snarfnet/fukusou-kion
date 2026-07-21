using ShinobiZero.Core;
using UnityEngine;
using UnityEngine.UI;

namespace ShinobiZero.Runtime
{
    public sealed class TutorialController : MonoBehaviour
    {
        private const string SeenKey = "shinobi-zero.tutorial-seen.v1";
        [SerializeField] private GameObject panel;
        [SerializeField] private Text stepText;
        [SerializeField] private Text titleText;
        [SerializeField] private Text guideText;
        [SerializeField] private Button nextButton;
        [SerializeField] private Button skipButton;
        [SerializeField] private Button replayButton;
        [SerializeField] private UiLocalizationController localization;

        private readonly TutorialFlow _flow = new TutorialFlow();
        private TutorialInputMode _inputMode;

        private void Awake()
        {
            nextButton.onClick.AddListener(Next);
            skipButton.onClick.AddListener(Skip);
            replayButton.onClick.AddListener(Show);
            panel.SetActive(false);
        }

        private void OnEnable()
        {
            if (localization != null) localization.LanguageChanged += HandleLanguageChanged;
        }

        private void OnDisable()
        {
            if (localization != null) localization.LanguageChanged -= HandleLanguageChanged;
        }

        private void Start()
        {
            if (PlayerPrefs.GetInt(SeenKey, 0) == 0) Show();
        }

        private void Update()
        {
            if (!panel.activeSelf || _flow.Page != TutorialPage.Throwing) return;
            var detected = InputModeDetector.Detect(_inputMode);
            if (detected == _inputMode) return;
            _inputMode = detected;
            Render();
        }

        public void Show()
        {
            _flow.Restart();
            _inputMode = InputModeDetector.Default();
            panel.SetActive(true);
            Render();
        }

        private void Next()
        {
            _flow.Next();
            if (_flow.IsComplete) { Complete(); return; }
            Render();
        }

        private void Skip()
        {
            _flow.Skip();
            Complete();
        }

        private void Complete()
        {
            PlayerPrefs.SetInt(SeenKey, 1);
            PlayerPrefs.Save();
            panel.SetActive(false);
        }

        private void Render()
        {
            var english = localization != null && localization.Language == GameLanguage.English;
            stepText.text = _flow.PageNumber + " / 3";
            if (_flow.Page == TutorialPage.Throwing)
            {
                titleText.text = english ? "THROW THE SHURIKEN" : "手裏剣を投げる";
                guideText.text = TutorialThrowGuide.Text(_inputMode, english ? GameLanguage.English : GameLanguage.Japanese);
            }
            else if (_flow.Page == TutorialPage.Scoring)
            {
                titleText.text = english ? "CUT DOWN THE SCORE" : "得点を削る";
                guideText.text = english
                    ? "The thin inner ring triples. The outer ring doubles.\nThe center BULL scores 50.\nTurns change after three throws."
                    : "細い内側の輪は3倍、外側の輪は2倍。\n中央のBULLは50点です。\n3投ごとに相手と交代します。";
            }
            else
            {
                titleText.text = english ? "FINISH ON ZERO" : "零で決める";
                guideText.text = english
                    ? "In DOUBLE OUT, finish on a double ring or BULL.\nPass zero and you BUST, returning\nto the score at the start of your turn."
                    : "DOUBLE OUTでは最後を2倍の輪か\nBULLで決めます。零を超えるとBUST。\nそのターン開始時の点数へ戻ります。";
            }
            nextButton.GetComponentInChildren<Text>().text = _flow.Page == TutorialPage.Checkout
                ? (english ? "BEGIN" : "始める") : (english ? "NEXT" : "次へ");
        }

        private void HandleLanguageChanged(GameLanguage language)
        {
            if (panel.activeSelf) Render();
        }

    }
}
