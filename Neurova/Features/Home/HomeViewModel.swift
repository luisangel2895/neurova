import Combine
import Foundation
import SwiftData

final class HomeViewModel: ObservableObject {
    @Published var state: HomeState
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var language: AppLanguage
    private var cachedState: HomeState?
    private var lastLoadDate: Date?
    private var lastContextIdentifier: ObjectIdentifier?
    private let cacheTTL: TimeInterval = 1.5

    init(language: AppLanguage = .spanish) {
        self.language = language
        self.state = .placeholder
    }

    func updateLanguage(_ language: AppLanguage) {
        guard self.language != language else { return }
        self.language = language
        cachedState = nil
    }

    func load(using context: ModelContext, forceRefresh: Bool = false) {
        let contextIdentifier = ObjectIdentifier(context)
        if forceRefresh == false,
           let cachedState,
           let lastLoadDate,
           lastContextIdentifier == contextIdentifier,
           Date().timeIntervalSince(lastLoadDate) <= cacheTTL {
            state = cachedState
            return
        }

        guard isLoading == false else { return }
        isLoading = true
        errorMessage = nil

        do {
            let useCases = HomeUseCases(context: context)
            let snapshot = try useCases.makeState(language: language)
            state = snapshot
            cachedState = snapshot
            lastLoadDate = Date()
            lastContextIdentifier = contextIdentifier
        } catch {
            errorMessage = "Unable to load home."
        }

        isLoading = false
    }

    func studyCounts(for deck: Deck, using context: ModelContext) -> [StudyCardFilter: Int] {
        HomeUseCases(context: context).studyCounts(for: deck)
    }

    func studyCards(
        for deck: Deck,
        filter: StudyCardFilter,
        using context: ModelContext
    ) -> [Card] {
        HomeUseCases(context: context).studyCards(for: deck, filter: filter)
    }
}
