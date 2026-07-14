import Foundation

protocol RecoveryRuleEngineProtocol {
    func generatePlan(categories: [LostItemCategory], location: LostLocation, lostDate: Date, currentDate: Date) -> RecoveryPlan
}

struct RecoveryRuleEngine: RecoveryRuleEngineProtocol {
    func generatePlan(categories: [LostItemCategory], location: LostLocation, lostDate: Date, currentDate: Date = Date()) -> RecoveryPlan {
        let isPassport = categories.contains(.passport)
        let isCard = categories.contains(.creditCard)
        let isPhone = categories.contains(.smartphone)
        let isTransit = [.train, .station, .subway, .bulletTrain, .bus].contains(location.category)

        let now: RecoveryAction
        if isCard { now = action("plan.stopCard", "plan.stopCard.detail", true) }
        else if isPhone { now = action("plan.findPhone", "plan.findPhone.detail", true) }
        else if isTransit { now = action("plan.askStation", "plan.askStation.detail", true) }
        else { now = action("plan.askPlace", "plan.askPlace.detail", false) }

        var next = [RecoveryAction]()
        if isTransit { next.append(action("plan.shareRoute", "plan.shareRoute.detail")) }
        next.append(action("plan.searchNearby", "plan.searchNearby.detail"))
        if isPassport { next.append(action("plan.policeReport", "plan.policeReport.detail", true)) }
        else { next.append(action("plan.contactPolice", "plan.contactPolice.detail")) }

        return RecoveryPlan(
            now: now,
            next: Array(next.prefix(3)),
            ifNotFound: action("plan.followUp", "plan.followUp.detail"),
            beforeDeparture: isPassport ? action("plan.embassy", "plan.embassy.detail", true) : nil
        )
    }

    private func action(_ title: String, _ detail: String, _ urgent: Bool = false) -> RecoveryAction {
        RecoveryAction(title: L10n.text(title), detail: L10n.text(detail), isUrgent: urgent)
    }
}

enum UrgencyResolver {
    static func resolve(_ categories: [LostItemCategory]) -> UrgencyLevel {
        let a: Set<LostItemCategory> = [.passport, .smartphone, .creditCard, .residenceCard, .medicine, .childItem]
        let b: Set<LostItemCategory> = [.wallet, .cash, .keys, .suitcase, .bag, .camera]
        if !a.isDisjoint(with: categories) { return .a }
        if !b.isDisjoint(with: categories) { return .b }
        return .c
    }
}
