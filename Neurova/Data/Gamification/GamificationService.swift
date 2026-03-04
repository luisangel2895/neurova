import Foundation
import SwiftData

struct GamificationSnapshot {
    let totalXP: Int
    let todayXP: Int
    let currentLevel: Int
    let progressToNextLevel: Double
    let xpToNextLevel: Int
}

struct GamificationService {
    private let repository: any XPEventRepository
    private let levelSystem: LevelSystem
    private let dateProvider: any DateProvider

    init(
        context: ModelContext,
        levelSystem: LevelSystem = LevelSystem(),
        dateProvider: any DateProvider = SystemDateProvider()
    ) {
        self.repository = SwiftDataXPEventRepository(context: context)
        self.levelSystem = levelSystem
        self.dateProvider = dateProvider
    }

    init(
        repository: any XPEventRepository,
        levelSystem: LevelSystem = LevelSystem(),
        dateProvider: any DateProvider = SystemDateProvider()
    ) {
        self.repository = repository
        self.levelSystem = levelSystem
        self.dateProvider = dateProvider
    }

    func snapshot() throws -> GamificationSnapshot {
        let totalXP = try repository.totalXP()
        let todayXP = try repository.todayXP(on: dateProvider.now, calendar: dateProvider.calendar)

        return GamificationSnapshot(
            totalXP: totalXP,
            todayXP: todayXP,
            currentLevel: levelSystem.level(for: totalXP),
            progressToNextLevel: levelSystem.progressToNextLevel(for: totalXP),
            xpToNextLevel: levelSystem.xpToNextLevel(for: totalXP)
        )
    }
}
