using System;
using System.Collections.Generic;
using ShinobiZero.Core;
using UnityEngine;
using UnityEngine.UI;

namespace ShinobiZero.Runtime
{
    public sealed class UiLocalizationController : MonoBehaviour
    {
        public GameLanguage Language { get; private set; } = GameLanguage.Japanese;
        public event Action<GameLanguage> LanguageChanged;

        private readonly List<Entry> _entries = new List<Entry>();
        private bool _captured;

        private struct Entry
        {
            public Text Text;
            public string Japanese;
        }

        private void Start()
        {
            var texts = GetComponentsInChildren<Text>(true);
            for (var i = 0; i < texts.Length; i++)
                _entries.Add(new Entry { Text = texts[i], Japanese = texts[i].text });
            _captured = true;
            ApplyLiterals();
            LanguageChanged?.Invoke(Language);
        }

        public void SetLanguage(GameLanguage language)
        {
            var changed = Language != language;
            Language = language;
            if (_captured) ApplyLiterals();
            if (changed) LanguageChanged?.Invoke(Language);
        }

        private void ApplyLiterals()
        {
            for (var i = 0; i < _entries.Count; i++)
                if (_entries[i].Text != null)
                    _entries[i].Text.text = LocalizationCatalog.Literal(_entries[i].Japanese, Language);
        }
    }
}
