/// What is waiting to be applied to one window. A slow app gets only the latest animation step,
/// never a backlog: a newer step merges into the waiting one. A final step (settle, park) replaces
/// everything before it and is never dropped or overtaken by an older step.
public struct StepQueue: Equatable, Sendable {
    /// At most two: a final step, then one non-final step after it.
    private(set) var steps: [FrameStep] = []

    public init() {}

    public var isEmpty: Bool {
        steps.isEmpty
    }

    public mutating func push(_ step: FrameStep) {
        switch step {
        case .settle, .park:
            steps = [step]
        case .place:
            dropTrailingNonFinal()
            steps.append(step)
        case .resize, .move:
            if let last = steps.last, !last.isFinal {
                steps[steps.count - 1] = last.merged(with: step)
            } else {
                steps.append(step)
            }
        }
    }

    public mutating func pop() -> FrameStep? {
        steps.isEmpty ? nil : steps.removeFirst()
    }

    private mutating func dropTrailingNonFinal() {
        if let last = steps.last, !last.isFinal {
            steps.removeLast()
        }
    }
}
