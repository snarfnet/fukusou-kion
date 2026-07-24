import Foundation
#if canImport(Combine)
import Combine

@MainActor
final class GameProgress: ObservableObject {
    @Published private(set) var cleared: Set<Int>

    private let defaults: UserDefaults
    private let key = "sukebanMahjong.clearedSchools"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let saved = defaults.array(forKey: key) as? [Int] ?? [0]
        let stored = Set(saved).intersection(0..<StoryData.heroines.count)
        var contiguous: Set<Int> = [0]
        for schoolID in 1..<StoryData.heroines.count {
            guard stored.contains(schoolID) else { break }
            contiguous.insert(schoolID)
        }
        self.cleared = contiguous
    }

    func clear(_ schoolID: Int) {
        guard (1..<StoryData.heroines.count).contains(schoolID),
              schoolID <= cleared.count else { return }
        cleared.insert(schoolID)
        save()
    }

    func reset() {
        cleared = [0]
        save()
    }

    private func save() {
        defaults.set(cleared.sorted(), forKey: key)
    }
}
#endif
