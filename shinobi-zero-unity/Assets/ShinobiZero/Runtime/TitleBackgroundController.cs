using UnityEngine;
using UnityEngine.UI;
using ShinobiZero.Core;

namespace ShinobiZero.Runtime
{
    [RequireComponent(typeof(Image), typeof(AspectRatioFitter))]
    public sealed class TitleBackgroundController : MonoBehaviour
    {
        [SerializeField] private Image image;
        [SerializeField] private AspectRatioFitter fitter;
        [SerializeField] private Sprite portrait;
        [SerializeField] private Sprite landscape;
        private bool? _landscapeApplied;
        public bool ReducedMotion { get; set; }

        private void Awake() => Apply();
        private void OnEnable() => Apply();
        private void OnRectTransformDimensionsChange() => Apply();

        private void Update()
        {
            if (image == null) return;
            var motion = TitleMotionModel.Evaluate(Time.unscaledTime, Screen.width > Screen.height, ReducedMotion);
            image.rectTransform.localScale = new Vector3(motion.Scale, motion.Scale, 1f);
            image.rectTransform.anchoredPosition = new Vector2(motion.X, motion.Y);
        }

        private void OnDisable()
        {
            if (image == null) return;
            image.rectTransform.localScale = Vector3.one;
            image.rectTransform.anchoredPosition = Vector2.zero;
        }

        private void Apply()
        {
            if (image == null || fitter == null || portrait == null || landscape == null) return;
            var useLandscape = Screen.width > Screen.height;
            if (_landscapeApplied.HasValue && _landscapeApplied.Value == useLandscape) return;
            var sprite = useLandscape ? landscape : portrait;
            image.sprite = sprite;
            fitter.aspectRatio = sprite.rect.width / sprite.rect.height;
            _landscapeApplied = useLandscape;
        }
    }
}
