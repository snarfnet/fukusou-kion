import XCTest
import Foundation
@testable import SukebanMahjong

final class StoryDataTests: XCTestCase {
    func testSixCharactersHaveDistinctShowaLooksAndCompleteProfiles() {
        let heroines = StoryData.heroines

        XCTAssertEqual(heroines.count, 6)
        XCTAssertEqual(heroines.map(\.id), Array(0...5))
        XCTAssertEqual(Set(heroines.map(\.name)).count, 6)
        XCTAssertEqual(Set(heroines.map(\.hair)).count, 6)
        XCTAssertEqual(Set(heroines.map(\.palette)).count, 6)

        for heroine in heroines {
            XCTAssertFalse(heroine.alias.isEmpty)
            XCTAssertFalse(heroine.school.isEmpty)
            XCTAssertFalse(heroine.region.isEmpty)
            XCTAssertFalse(heroine.appearance.isEmpty)
            XCTAssertFalse(heroine.story.isEmpty)
            XCTAssertFalse(heroine.secret.isEmpty)
            XCTAssertFalse(heroine.specialty.isEmpty)
            XCTAssertFalse(heroine.favoriteFood.isEmpty)
            XCTAssertFalse(heroine.favoriteType.isEmpty)
            XCTAssertFalse(heroine.favoriteMotorcycle.isEmpty)
            XCTAssertFalse(heroine.favoriteCar.isEmpty)
        }
    }

    func testNationwideRosterContainsExactlyOneHundredCompleteCharacters() {
        let all = StoryData.allCharacters
        let supporting = StoryData.supporting

        XCTAssertEqual(all.count, 100)
        XCTAssertEqual(supporting.count, 94)
        XCTAssertEqual(all.map(\.id), Array(0..<100))
        XCTAssertEqual(Set(all.map(\.name)).count, 100)
        XCTAssertEqual(Set(supporting.map(\.region)).count, 47)

        for region in Set(supporting.map(\.region)) {
            XCTAssertEqual(supporting.filter { $0.region == region }.count, 2, region)
        }
        for girl in supporting {
            XCTAssertFalse(girl.alias.isEmpty)
            XCTAssertFalse(girl.school.isEmpty)
            XCTAssertFalse(girl.appearance.isEmpty)
            XCTAssertFalse(girl.story.isEmpty)
            XCTAssertFalse(girl.secret.isEmpty)
            XCTAssertFalse(girl.specialty.isEmpty)
            XCTAssertFalse(girl.favoriteFood.isEmpty)
            XCTAssertFalse(girl.favoriteType.isEmpty)
            XCTAssertFalse(girl.favoriteMotorcycle.isEmpty)
            XCTAssertFalse(girl.favoriteCar.isEmpty)
        }

        XCTAssertGreaterThanOrEqual(Set(all.map(\.favoriteFood)).count, 20)
        XCTAssertGreaterThanOrEqual(Set(all.map(\.favoriteType)).count, 20)
        XCTAssertGreaterThanOrEqual(Set(all.map(\.favoriteMotorcycle)).count, 20)
        XCTAssertGreaterThanOrEqual(Set(all.map(\.favoriteCar)).count, 20)

        let preferenceProfiles = Set(all.map {
            [
                $0.favoriteFood,
                $0.favoriteType,
                $0.favoriteMotorcycle,
                $0.favoriteCar
            ].joined(separator: "|")
        })
        XCTAssertEqual(preferenceProfiles.count, 100)
    }

    func testEveryOpponentHasIntroAndOutroStoryScenes() {
        for opponent in StoryData.heroines.dropFirst() {
            let intro = StoryScenes.intro(for: opponent)
            let outro = StoryScenes.outro(for: opponent)
            let givenName = opponent.name.split(separator: " ").last.map(String.init)
                ?? opponent.name

            XCTAssertEqual(intro.count, 6, opponent.name)
            XCTAssertEqual(outro.count, 6, opponent.name)
            XCTAssertTrue(intro.contains { $0.speaker == "朱莉" })
            XCTAssertTrue(intro.contains { $0.speaker == givenName })
            XCTAssertTrue(outro.contains { $0.speaker == "朱莉" })
        }
    }

    func testOpponentTacticsMatchCharacterSpecialties() {
        let reika = StoryData.heroines[1].tactics
        let ran = StoryData.heroines[2].tactics
        let torako = StoryData.heroines[4].tactics
        let chizuru = StoryData.heroines[5].tactics

        XCTAssertEqual(reika.callChance, 1)
        XCTAssertEqual(ran.callChance, 6)
        XCTAssertEqual(torako.kanChance, 6)
        XCTAssertEqual(chizuru.smartDiscardChance, 6)
        XCTAssertGreaterThan(chizuru.smartDiscardChance, reika.smartDiscardChance)
    }

    func testStoryHasSixtySixChaptersAndSixPartEpilogue() {
        XCTAssertEqual(StoryScenes.allChapters.count, 66)
        XCTAssertEqual(StoryScenes.allChapters.compactMap(\.chapterNumber), Array(1...66))
        XCTAssertEqual(Set(StoryScenes.allChapters.compactMap(\.chapterTitle)).count, 66)
        XCTAssertEqual(StoryScenes.prologue.count, 6)
        XCTAssertEqual(StoryScenes.epilogue.count, 6)

        for opponent in StoryData.heroines.dropFirst() {
            XCTAssertEqual(StoryScenes.intro(for: opponent).count, 6)
            XCTAssertEqual(StoryScenes.outro(for: opponent).count, 6)
        }

        for heroine in StoryData.heroines {
            let givenName = heroine.name.split(separator: " ").last.map(String.init)
                ?? heroine.name
            XCTAssertTrue(
                StoryScenes.epilogue.contains { $0.contains(givenName) },
                "\(heroine.name)の後日談がありません"
            )
        }
    }

    func testStoryUsesHistoricallyPossibleShowaSpring() {
        let prologue = StoryScenes.prologue.map(\.text).joined()
        XCTAssertTrue(prologue.contains("昭和六十三年、春"))
        XCTAssertFalse(prologue.contains("昭和六十四年、春"))
    }

    func testStoryArchiveUnlocksTwelveChaptersPerConqueredSchool() {
        XCTAssertEqual(StoryScenes.unlockedChapterCount(clearedSchoolCount: 1), 6)
        XCTAssertEqual(StoryScenes.unlockedChapterCount(clearedSchoolCount: 2), 18)
        XCTAssertEqual(StoryScenes.unlockedChapterCount(clearedSchoolCount: 5), 54)
        XCTAssertEqual(StoryScenes.unlockedChapterCount(clearedSchoolCount: 6), 66)
        XCTAssertEqual(StoryScenes.unlockedChapterCount(clearedSchoolCount: 99), 66)
    }

    func testEverySupportingCharacterAppearsInMainStory() throws {
        let featured = Set(StoryScenes.allChapters.flatMap(\.featuredCharacterIDs))
        XCTAssertEqual(featured, Set(6..<100))

        let sumire = try XCTUnwrap(
            StoryData.supporting.first { $0.name == "九十九 菫" }
        )
        let chapter57 = try XCTUnwrap(
            StoryScenes.allChapters.first { $0.chapterNumber == 57 }
        )
        XCTAssertTrue(chapter57.featuredCharacterIDs.contains(sumire.id))
    }

#if canImport(Combine)
    @MainActor
    func testProgressRejectsSkippedAndUnknownSchools() {
        let suiteName = "GameProgressTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set([0, 2, 99], forKey: "sukebanMahjong.clearedSchools")

        let progress = GameProgress(defaults: defaults)
        XCTAssertEqual(progress.cleared, [0])

        progress.clear(2)
        XCTAssertEqual(progress.cleared, [0])
        progress.clear(1)
        progress.clear(2)
        XCTAssertEqual(progress.cleared, [0, 1, 2])
    }
#endif
}
