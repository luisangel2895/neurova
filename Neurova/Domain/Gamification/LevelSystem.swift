import Foundation

struct LevelSystem {
    private let baseStep: Int

    init(baseStep: Int = 100) {
        self.baseStep = max(baseStep, 1)
    }

    func level(for totalXP: Int) -> Int {
        let safeXP = max(totalXP, 0)
        var level = 1

        while xpRequiredToReachLevel(level + 1) <= safeXP {
            level += 1
        }

        return level
    }

    func xpToNextLevel(for totalXP: Int) -> Int {
        let safeXP = max(totalXP, 0)
        let currentLevel = level(for: safeXP)
        let nextLevelXP = xpRequiredToReachLevel(currentLevel + 1)
        return max(nextLevelXP - safeXP, 0)
    }

    func progressToNextLevel(for totalXP: Int) -> Double {
        let safeXP = max(totalXP, 0)
        let currentLevel = level(for: safeXP)
        let currentThreshold = xpRequiredToReachLevel(currentLevel)
        let nextThreshold = xpRequiredToReachLevel(currentLevel + 1)
        let span = max(nextThreshold - currentThreshold, 1)
        let progress = Double(safeXP - currentThreshold) / Double(span)
        return min(max(progress, 0), 1)
    }

    private func xpRequiredToReachLevel(_ level: Int) -> Int {
        guard level > 1 else { return 0 }
        let previousLevel = level - 1
        return baseStep * previousLevel * level / 2
    }
}
