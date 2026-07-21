namespace ShinobiZero.Core
{
    public struct LayoutPoint
    {
        public readonly float X;
        public readonly float Y;
        public LayoutPoint(float x, float y) { X = x; Y = y; }
    }

    public static class ResponsiveLayoutModel
    {
        public const float PortraitReferenceWidth = 1080f;
        public const float PortraitReferenceHeight = 1920f;
        public const float LandscapeReferenceWidth = 1600f;
        public const float LandscapeReferenceHeight = 900f;
        public const float LandscapeHorizontalSpread = 1.55f;
        public const float LandscapeVerticalCompression = .55f;
        public const float LandscapeHeightCompression = .72f;

        public static bool IsLandscape(float width, float height)
        {
            return width > 0f && height > 0f && width >= height * 1.2f;
        }

        public static LayoutPoint Position(float x, float y, bool landscape)
        {
            return landscape
                ? new LayoutPoint(x * LandscapeHorizontalSpread, y * LandscapeVerticalCompression)
                : new LayoutPoint(x, y);
        }

        public static LayoutPoint Size(float width, float height, bool landscape)
        {
            return landscape
                ? new LayoutPoint(width, height * LandscapeHeightCompression)
                : new LayoutPoint(width, height);
        }

        public static float ScaleFactor(float screenWidth, float screenHeight, bool landscape)
        {
            if (screenWidth <= 0f || screenHeight <= 0f) return 0f;
            var referenceWidth = landscape ? LandscapeReferenceWidth : PortraitReferenceWidth;
            var referenceHeight = landscape ? LandscapeReferenceHeight : PortraitReferenceHeight;
            return (float)System.Math.Sqrt((screenWidth / referenceWidth) * (screenHeight / referenceHeight));
        }

        public static float PhysicalPixels(float authoredPixels, float screenWidth, float screenHeight, bool landscape)
        {
            return authoredPixels * ScaleFactor(screenWidth, screenHeight, landscape);
        }
    }
}
