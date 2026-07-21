using System;

namespace ShinobiZero.Core
{
    public struct BoardAim
    {
        public readonly float X;
        public readonly float Y;
        public BoardAim(float x, float y) { X = x; Y = y; }
    }

    public static class ScreenAimModel
    {
        public static BoardAim Map(float pointerX, float pointerY, float boardCenterX, float boardCenterY, float boardRadiusPixels, float maximumRadius = 1.25f)
        {
            if (boardRadiusPixels <= 0f) return new BoardAim(0f, 0f);
            var x = (pointerX - boardCenterX) / boardRadiusPixels;
            var y = (pointerY - boardCenterY) / boardRadiusPixels;
            var length = Math.Sqrt(x * x + y * y);
            if (length > maximumRadius && length > 0d)
            {
                var scale = maximumRadius / length;
                x = (float)(x * scale);
                y = (float)(y * scale);
            }
            return new BoardAim(x, y);
        }
    }
}
