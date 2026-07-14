import Foundation

struct RecoveryAction: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let detail: String
    let isUrgent: Bool
}

struct RecoveryPlan {
    let now: RecoveryAction
    let next: [RecoveryAction]
    let ifNotFound: RecoveryAction
    let beforeDeparture: RecoveryAction?
}

