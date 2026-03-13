import Testing
@testable import Neurova

struct LevelSystemTests {
    @Test
    func levelProgressionUsesTriangularThresholds() {
        let system = LevelSystem(baseStep: 100)

        #expect(system.level(for: 0) == 1)
        #expect(system.level(for: 99) == 1)
        #expect(system.level(for: 100) == 2)
        #expect(system.level(for: 299) == 2)
        #expect(system.level(for: 300) == 3)
    }

    @Test
    func progressAndRemainingXPAreConsistent() {
        let system = LevelSystem(baseStep: 100)

        #expect(system.xpToNextLevel(for: 150) == 150)
        #expect(system.progressToNextLevel(for: 150) == 0.25)
    }

    @Test
    func negativeXPIsClampedSafely() {
        let system = LevelSystem(baseStep: 100)

        #expect(system.level(for: -50) == 1)
        #expect(system.xpToNextLevel(for: -50) == 100)
        #expect(system.progressToNextLevel(for: -50) == 0)
    }
}
