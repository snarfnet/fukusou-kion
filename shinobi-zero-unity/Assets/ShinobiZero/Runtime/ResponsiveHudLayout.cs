using System.Collections.Generic;
using ShinobiZero.Core;
using UnityEngine;
using UnityEngine.UI;

namespace ShinobiZero.Runtime
{
    [RequireComponent(typeof(CanvasScaler))]
    public sealed class ResponsiveHudLayout : MonoBehaviour
    {
        [SerializeField] private RectTransform[] layoutRoots;

        private readonly List<Entry> _entries = new List<Entry>();
        private CanvasScaler _scaler;
        private bool? _landscape;
        private bool _captured;

        private struct Entry
        {
            public RectTransform Rect;
            public Vector2 Position;
            public Vector2 Size;
            public bool FixedAnchors;
        }

        private void Awake()
        {
            _scaler = GetComponent<CanvasScaler>();
            Capture();
            Apply(Screen.width, Screen.height, true);
        }

        private void OnRectTransformDimensionsChange()
        {
            if (!_captured) return;
            Apply(Screen.width, Screen.height, false);
        }

        public void Apply(int width, int height, bool force = false)
        {
            var landscape = ResponsiveLayoutModel.IsLandscape(width, height);
            if (!force && _landscape.HasValue && _landscape.Value == landscape) return;
            _landscape = landscape;
            _scaler.referenceResolution = landscape
                ? new Vector2(ResponsiveLayoutModel.LandscapeReferenceWidth, ResponsiveLayoutModel.LandscapeReferenceHeight)
                : new Vector2(ResponsiveLayoutModel.PortraitReferenceWidth, ResponsiveLayoutModel.PortraitReferenceHeight);
            _scaler.matchWidthOrHeight = .5f;

            for (var i = 0; i < _entries.Count; i++)
            {
                var entry = _entries[i];
                if (entry.Rect == null) continue;
                var position = ResponsiveLayoutModel.Position(entry.Position.x, entry.Position.y, landscape);
                entry.Rect.anchoredPosition = new Vector2(position.X, position.Y);
                if (!entry.FixedAnchors) continue;
                var size = ResponsiveLayoutModel.Size(entry.Size.x, entry.Size.y, landscape);
                entry.Rect.sizeDelta = new Vector2(size.X, size.Y);
            }
        }

        private void Capture()
        {
            _entries.Clear();
            if (layoutRoots != null)
            {
                for (var rootIndex = 0; rootIndex < layoutRoots.Length; rootIndex++)
                {
                    var root = layoutRoots[rootIndex];
                    if (root == null) continue;
                    for (var childIndex = 0; childIndex < root.childCount; childIndex++)
                    {
                        var rect = root.GetChild(childIndex) as RectTransform;
                        if (rect == null) continue;
                        _entries.Add(new Entry
                        {
                            Rect = rect,
                            Position = rect.anchoredPosition,
                            Size = rect.sizeDelta,
                            FixedAnchors = rect.anchorMin == rect.anchorMax
                        });
                    }
                }
            }
            _captured = true;
        }
    }
}
