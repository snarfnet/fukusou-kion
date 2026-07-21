using UnityEngine;

namespace ShinobiZero.Runtime
{
    public sealed class NinjaVisualController : MonoBehaviour
    {
        [SerializeField] private Renderer[] clothRenderers;
        [SerializeField] private Renderer[] accentRenderers;

        public void Configure(OpponentProfile profile)
        {
            if (profile == null) return;
            SetColor(clothRenderers, profile.OutfitColor);
            SetColor(accentRenderers, profile.AccentColor);
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
