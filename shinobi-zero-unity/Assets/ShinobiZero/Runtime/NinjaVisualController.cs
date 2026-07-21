using UnityEngine;

namespace ShinobiZero.Runtime
{
    public sealed class NinjaVisualController : MonoBehaviour
    {
        [SerializeField] private Renderer[] clothRenderers;
        [SerializeField] private Renderer[] accentRenderers;
        [SerializeField] private Transform characterRoot;
        [SerializeField] private GameObject[] styleAccessories;

        public void Configure(OpponentProfile profile)
        {
            if (profile == null) return;
            SetColor(clothRenderers, profile.OutfitColor);
            SetColor(accentRenderers, profile.AccentColor);
            if (characterRoot != null) characterRoot.localScale = profile.BodyScale;
            if (styleAccessories == null) return;
            for (var i = 0; i < styleAccessories.Length; i++)
                if (styleAccessories[i] != null) styleAccessories[i].SetActive(i == (int)profile.VisualStyle);
        }

        private static void SetColor(Renderer[] renderers, Color color)
        {
            if (renderers == null) return;
            for (var i = 0; i < renderers.Length; i++)
            {
                if (renderers[i] == null) continue;
                renderers[i].material.color = color;
            }
        }
    }
}
