import Foundation
import Testing
@testable import Neurova

struct GamificationServiceTests {
    @Test
    func snapshotReturnsCorrectLevelAndProgress() throws {
        let repo = MockXPEventRepository()
        repo.storedTotalXP = 150
        repo.storedTodayXP = 30

        let service = GamificationService(
            repository: repo,
            levelSystem: LevelSystem(baseStep: 100),
            dateProvider: MockDateProvider()
        )

        let snapshot = try service.snapshot()

        #expect(snapshot.totalXP == 150)
        #expect(snapshot.todayXP == 30)
        #expect(snapshot.currentLevel == 2)
        #expect(snapshot.progressToNextLevel == 0.25)
        #expect(snapshot.xpToNextLevel == 150)
    }

    @Test
    func snapshotWithZeroXPReturnsLevelOne() throws {
        let repo = MockXPEventRepository()
        repo.storedTotalXP = 0
        repo.storedTodayXP = 0

        let service = GamificationService(
            repository: repo,
            dateProvider: MockDateProvider()
        )

        let snapshot = try service.snapshot()

        #expect(snapshot.currentLevel == 1)
        #expect(snapshot.progressToNextLevel == 0)
    }

    @Test
    func snapshotThrowsWhenRepositoryFails() {
        let repo = MockXPEventRepository()
        repo.shouldThrow = true

        let service = GamificationService(
            repository: repo,
            dateProvider: MockDateProvider()
        )

        #expect(throws: MockError.self) {
            try service.snapshot()
        }
    }
}
