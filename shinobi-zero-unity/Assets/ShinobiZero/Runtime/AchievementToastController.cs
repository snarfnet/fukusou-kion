using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using ShinobiZero.Core;

namespace ShinobiZero.Runtime
{
    public sealed class AchievementToastController : MonoBehaviour
    {
        [SerializeField] private PlayerProgressController progress;
        [SerializeField] private GameObject panel;
        [SerializeField] private Text titleText;
        [SerializeField] private UiLocalizationController localization;
        private Coroutine _activeToast;
        private readonly Queue<ToastMessage> _pending = new Queue<ToastMessage>();

        private struct ToastMessage
        {
            public string AchievementId;
            public CareerRank Rank;
            public bool IsRank;
        }

        private void Awake() => panel.SetActive(false);

        private void OnEnable()
        {
            if (progress != null) progress.AchievementUnlocked += Show;
            if (progress != null) progress.RankPromoted += ShowRank;
        }

        private void OnDisable()
        {
            if (progress != null) progress.AchievementUnlocked -= Show;
            if (progress != null) progress.RankPromoted -= ShowRank;
            if (_activeToast != null) StopCoroutine(_activeToast);
            _activeToast = null;
            _pending.Clear();
            panel.SetActive(false);
        }

        private void Show(string id)
        {
            _pending.Enqueue(new ToastMessage { AchievementId = id });
            if (_activeToast == null) _activeToast = StartCoroutine(ShowQueue());
        }

        private void ShowRank(CareerRank rank)
        {
            _pending.Enqueue(new ToastMessage { Rank = rank, IsRank = true });
            if (_activeToast == null) _activeToast = StartCoroutine(ShowQueue());
        }

        private IEnumerator ShowQueue()
        {
            while (_pending.Count > 0)
            {
                var language = localization == null ? GameLanguage.Japanese : localization.Language;
                var message = _pending.Dequeue();
                titleText.text = message.IsRank
                    ? (language == GameLanguage.English ? "PROMOTED  " + CareerRankModel.English(message.Rank)
                        : "昇格　" + CareerRankModel.Japanese(message.Rank))
                    : (language == GameLanguage.English ? "ACHIEVEMENT  " : "実績解除　")
                        + AchievementCatalog.Title(message.AchievementId, language);
                panel.SetActive(true);
                yield return new WaitForSecondsRealtime(2.8f);
                panel.SetActive(false);
                yield return new WaitForSecondsRealtime(.18f);
            }
            panel.SetActive(false);
            _activeToast = null;
        }
    }
}
