import BloxCore
import BloxIPC

extension Controller {
    /// Answers one CLI request. Anything that is not a built-in query is a user command.
    func handle(_ request: String) -> String {
        switch request {
        case "version": return bloxVersion
        case "status": return summary
        case "stats": return animationStats
        case "reload": return reloadConfig().map { "error: \($0)" } ?? "ok"
        default:
            guard let command = Command(parsing: request)
            else { return "error: unknown command '\(request)'" }
            dispatch(command)
            return "ok"
        }
    }
}
