import XCTest
@testable import ShowThisJapan

final class ShowThisJapanTests: XCTestCase {
    func testPhraseDecoding() throws {
        let json = #"{"id":"x","categoryID":"food","iconName":"fork.knife","japaneseText":"水をください。","translations":{"en":"Water, please."},"searchKeywords":["water"],"responseType":"none","isEmergency":false}"#.data(using:.utf8)!
        XCTAssertEqual(try JSONDecoder().decode(PhraseCard.self,from:json).text(in:.en), "Water, please.")
    }
    @MainActor func testSearchAndRecentDeduplication() {
        let suite = UserDefaults(suiteName:#function)!; suite.removePersistentDomain(forName:#function)
        let vm = AppViewModel(defaults:suite,loadData:false)
        vm.cards = [.init(id:"pork",categoryID:"food",iconName:"",japaneseText:"豚肉",translations:["en":"Pork"],searchKeywords:["halal"],responseType:.yesNo,isEmergency:false)]
        XCTAssertEqual(vm.search("halal").count,1); vm.record("pork"); vm.record("pork"); XCTAssertEqual(vm.recentIDs,["pork"])
    }
    @MainActor func testFavoritesPersist() {
        let suite = UserDefaults(suiteName:#function)!; suite.removePersistentDomain(forName:#function)
        let vm = AppViewModel(defaults:suite,loadData:false); vm.toggleFavorite("one")
        XCTAssertTrue(AppViewModel(defaults:suite,loadData:false).favorites.contains("one"))
    }
}

