using UnityEngine;

namespace ShinobiZero.Runtime
{
    public enum OpponentVisualStyle { Rookie, Scout, Berserker, Veteran, Shadow }

    [CreateAssetMenu(menuName = "SHINOBI ZERO/Opponent Profile")]
    public sealed class OpponentProfile : ScriptableObject
    {
        [SerializeField] private string displayName = "カゲロウ";
        [SerializeField] private string title = "見習い";
        [SerializeField, TextArea] private string styleDescription = "安全策を好む。終盤に乱れやすい。";
        [SerializeField] private string englishDisplayName = "KAGERO";
        [SerializeField] private string englishTitle = "Apprentice";
        [SerializeField, TextArea] private string englishStyleDescription = "Steady scoring, but fragile late in the duel.";
        [SerializeField, Range(0f, 1f)] private float skill = .34f;
        [SerializeField, Range(1, 20)] private int preferredBase = 19;
        [SerializeField, Min(.1f)] private float thinkTime = .72f;
        [SerializeField, Range(0f, 1f)] private float aggression = .2f;
        [SerializeField, Range(0f, 1f)] private float pressureResistance = .3f;
        [SerializeField, Range(0f, 1f)] private float consistency = .45f;
        [SerializeField, Range(-.08f, .08f)] private float horizontalBias;
        [SerializeField] private OpponentStrategy strategy = OpponentStrategy.Rhythm;
        [SerializeField] private ThrowAnimationProfile animationProfile;
        [SerializeField] private Color outfitColor = new Color(.04f, .045f, .045f);
        [SerializeField] private Color accentColor = new Color(.18f, .19f, .18f);
        [SerializeField] private OpponentVisualStyle visualStyle;
        [SerializeField] private Vector3 bodyScale = Vector3.one;

        public string DisplayName { get { return displayName; } }
        public string Title { get { return title; } }
        public string StyleDescription { get { return styleDescription; } }
        public string EnglishDisplayName { get { return englishDisplayName; } }
        public string EnglishTitle { get { return englishTitle; } }
        public string EnglishStyleDescription { get { return englishStyleDescription; } }
        public float Skill { get { return skill; } }
        public int PreferredBase { get { return preferredBase; } }
        public float ThinkTime { get { return thinkTime; } }
        public float Aggression { get { return aggression; } }
        public float PressureResistance { get { return pressureResistance; } }
        public float Consistency { get { return consistency; } }
        public float HorizontalBias { get { return horizontalBias; } }
        public OpponentStrategy Strategy { get { return strategy; } }
        public ThrowAnimationProfile AnimationProfile { get { return animationProfile; } }
        public Color OutfitColor { get { return outfitColor; } }
        public Color AccentColor { get { return accentColor; } }
        public OpponentVisualStyle VisualStyle { get { return visualStyle; } }
        public Vector3 BodyScale { get { return bodyScale; } }
    }
}
