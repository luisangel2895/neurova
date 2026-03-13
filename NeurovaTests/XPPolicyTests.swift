import Testing
@testable import Neurova

struct XPPolicyTests {
    @Test
    func defaultPolicyMapsEveryEventTypeToExpectedXP() {
        let policy = DefaultXPPolicy()

        #expect(policy.xpDelta(for: .reviewAgain) == 0)
        #expect(policy.xpDelta(for: .reviewHard) == 5)
        #expect(policy.xpDelta(for: .skipHard) == 5)
        #expect(policy.xpDelta(for: .autoHardTimeout) == 5)
        #expect(policy.xpDelta(for: .reviewGood) == 10)
        #expect(policy.xpDelta(for: .reviewEasy) == 15)
    }
}
