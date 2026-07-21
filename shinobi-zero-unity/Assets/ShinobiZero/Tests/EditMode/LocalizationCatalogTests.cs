using NUnit.Framework;
using ShinobiZero.Core;

namespace ShinobiZero.Tests
{
    public sealed class LocalizationCatalogTests
    {
        [Test] public void JapaneseLiteralIsUnchanged() =>
            Assert.That(LocalizationCatalog.Literal("設定", GameLanguage.Japanese), Is.EqualTo("設定"));

        [Test] public void FixedMenuLiteralHasEnglishTranslation() =>
            Assert.That(LocalizationCatalog.Literal("対戦を始める", GameLanguage.English), Is.EqualTo("BEGIN DUEL"));

        [Test] public void DesktopQuitHasEnglishTranslation() =>
            Assert.That(LocalizationCatalog.Literal("終了", GameLanguage.English), Is.EqualTo("QUIT"));

        [Test] public void AimSensitivityHasEnglishTranslation() =>
            Assert.That(LocalizationCatalog.Literal("照準感度", GameLanguage.English), Is.EqualTo("AIM SENSITIVITY"));

        [Test] public void UnknownProperNounIsPreserved() =>
            Assert.That(LocalizationCatalog.Literal("SHINOBI ZERO", GameLanguage.English), Is.EqualTo("SHINOBI ZERO"));

        [Test] public void EveryOpponentStrategyHasEnglishName()
        {
            for (var i = 0; i < OpponentTuningCatalog.Count; i++)
                Assert.That(OpponentStrategyNames.English(OpponentTuningCatalog.Get(i).Strategy), Is.Not.Empty);
        }

        [Test] public void EveryAchievementHasEnglishTitle()
        {
            var ids = AchievementCatalog.Evaluate(new CareerStats
            {
                Wins = 10, BestCheckout = 100, BestTurn = 180, Bulls = 25,
                OpponentWins = new[] { 1, 1, 1, 1, 1 }
            });
            Assert.That(ids.Length, Is.EqualTo(6));
            for (var i = 0; i < ids.Length; i++) Assert.That(AchievementCatalog.EnglishTitle(ids[i]), Is.Not.EqualTo(ids[i]));
        }

        [Test] public void StableAchievementIdLocalizesAtDisplayTime()
        {
            Assert.That(AchievementCatalog.Title(AchievementCatalog.MaximumTurn, GameLanguage.Japanese), Is.EqualTo("一八〇・極"));
            Assert.That(AchievementCatalog.Title(AchievementCatalog.MaximumTurn, GameLanguage.English), Is.EqualTo("Perfect 180"));
            Assert.That(AchievementCatalog.Title("MOD_UNKNOWN", GameLanguage.English), Is.EqualTo("MOD_UNKNOWN"));
        }
    }
}
