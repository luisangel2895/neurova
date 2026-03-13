import Testing
@testable import Neurova

struct DailyGoalPolicyTests {
    @Test
    func defaultGoalUsesConfiguredValueAndClampsNegativeReviews() {
        let policy = DailyGoalPolicy(defaultGoal: 20)
        let result = policy.progress(for: -5)

        #expect(result.progressCount == 0)
        #expect(result.dailyGoal == 20)
        #expect(result.isGoalMet == false)
    }

    @Test
    func customGoalOverrideCanMarkGoalAsMet() {
        let policy = DailyGoalPolicy(defaultGoal: 20)
        let result = policy.progress(for: 12, dailyGoal: 10)

        #expect(result.progressCount == 12)
        #expect(result.dailyGoal == 10)
        #expect(result.isGoalMet)
    }

    @Test
    func invalidConfiguredGoalsAreFlooredToOne() {
        let policy = DailyGoalPolicy(defaultGoal: 0)
        let result = policy.progress(for: 0, dailyGoal: 0)

        #expect(result.dailyGoal == 1)
        #expect(result.isGoalMet == false)
    }
}
