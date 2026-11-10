@testable import BloxCore
import Testing

/// Random command sequences, checked after every step. A failure prints its seed and the
/// command trail so it can be replayed and shrunk into a plain regression test.
struct FuzzTests {
    private static let steps = 60

    private static func initialState() -> State {
        var state = makeState()
        state.settings.rules = RandomCommand.rules
        return state
    }

    /// Returns the first failure for `seed`, with the trail that led to it.
    private static func failure(seed: UInt64) -> String? {
        var rng = SplitMix64(seed: seed)
        var state = initialState()
        var os = SimulatedOS()
        var trail: [Command] = []
        for _ in 0 ..< steps {
            let command = RandomCommand.next(using: &rng)
            trail.append(command)
            let (next, effects) = reduce(state, command)
            os.apply(command, effects: effects)
            state = next
            let found = StateInvariants.violations(in: state) + os.problems + os.mismatches(against: state)
            let again = reduce(state, .retile)
            if let first = found.first ?? (again.1.isEmpty ? nil : "retile emitted \(again.1)") {
                let steps = trail.map { String(String(describing: $0).prefix(60)) }
                return "seed \(seed): \(first)\ntrail: \(steps.joined(separator: ", "))"
            }
        }
        return nil
    }

    @Test(arguments: 0 ..< 400) func `random sequences keep every invariant`(seed: Int) {
        #expect(Self.failure(seed: UInt64(seed)) == nil)
    }

    @Test func `reducer is deterministic`() {
        var rng = SplitMix64(seed: 7)
        var state = Self.initialState()
        for _ in 0 ..< Self.steps {
            let command = RandomCommand.next(using: &rng)
            let first = reduce(state, command)
            let second = reduce(state, command)
            #expect(first.0 == second.0 && first.1 == second.1)
            state = first.0
        }
    }
}
