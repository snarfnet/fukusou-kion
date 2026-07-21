using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class ResponsiveLayoutModelTests
    {
        [TestCase(1080f, 1920f, false)]
        [TestCase(1170f, 2532f, false)]
        [TestCase(1920f, 1080f, true)]
        [TestCase(1280f, 800f, true)]
        public void ClassifiesCommonIosAndSteamAspects(float width, float height, bool expected) =>
            Assert.That(ResponsiveLayoutModel.IsLandscape(width, height), Is.EqualTo(expected));

        [Test] public void PortraitCoordinatesRemainPixelExact()
        {
            var point = ResponsiveLayoutModel.Position(410f, 760f, false);
            var size = ResponsiveLayoutModel.Size(620f, 110f, false);
            Assert.That(point.X, Is.EqualTo(410f));
            Assert.That(point.Y, Is.EqualTo(760f));
            Assert.That(size.X, Is.EqualTo(620f));
            Assert.That(size.Y, Is.EqualTo(110f));
        }

        [Test] public void AuthoredVerticalExtremesFitLandscapeReference()
        {
            var top = ResponsiveLayoutModel.Position(0f, 760f, true);
            var bottom = ResponsiveLayoutModel.Position(0f, -760f, true);
            Assert.That(top.Y, Is.LessThan(540f));
            Assert.That(bottom.Y, Is.GreaterThan(-540f));
        }

        [Test] public void FiveOpponentRowSpreadsAcrossLandscape()
        {
            var left = ResponsiveLayoutModel.Position(-410f, 180f, true);
            var right = ResponsiveLayoutModel.Position(410f, 180f, true);
            Assert.That(left.X, Is.LessThan(-600f));
            Assert.That(right.X, Is.GreaterThan(600f));
            Assert.That(right.X, Is.LessThan(960f));
        }

        [Test] public void LandscapeControlsBecomeShorterWithoutChangingWidth()
        {
            var size = ResponsiveLayoutModel.Size(620f, 110f, true);
            Assert.That(size.X, Is.EqualTo(620f));
            Assert.That(size.Y, Is.EqualTo(79.2f).Within(.001f));
        }

        [Test] public void SteamDeckKeepsSmallestTextAtLeastEighteenPixels()
        {
            Assert.That(ResponsiveLayoutModel.PhysicalPixels(22f, 1280f, 800f, true), Is.GreaterThanOrEqualTo(18f));
        }

        [Test] public void SteamDeckKeepsSmallestButtonAtLeastFortyPixelsHigh()
        {
            var compressed = ResponsiveLayoutModel.Size(330f, 68f, true);
            Assert.That(ResponsiveLayoutModel.PhysicalPixels(compressed.Y, 1280f, 800f, true), Is.GreaterThanOrEqualTo(40f));
        }
    }
}
