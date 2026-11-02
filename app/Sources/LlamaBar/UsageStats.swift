import Foundation

/// OpenCode's usage statistics (`opencode stats --json`), covering every session
/// T3 Code and the TUI ran through bin/opencode-ollama.
struct UsageStats: Hashable, Decodable {
    let sessions: Int
    let prompts: Int
    let tokens: TokenCounts
    let models: [ModelUsage]?

    static func read(_ period: UsagePeriod, project: Project = .current) async throws -> UsageStats {
        let output = try await Shell.run(project.launcher, ["stats", "--json", "--models"] + period.statsArguments)
        return try JSONDecoder().decode(UsageStats.self, from: output)
    }
}

struct TokenCounts: Hashable, Decodable {
    struct Cache: Hashable, Decodable {
        let read: Int
        let write: Int
    }

    let input: Int
    let output: Int
    let cache: Cache
}

struct ModelUsage: Identifiable, Hashable, Decodable {
    struct Model: Hashable, Decodable {
        let id: String
        let providerID: String
    }

    let model: Model
    let steps: Int
    let tokens: TokenCounts

    var id: String { "\(model.providerID)/\(model.id)" }
}

enum UsagePeriod: String, CaseIterable, Identifiable {
    case today = "Today"
    case week = "7 Days"
    case month = "30 Days"
    case lifetime = "All"

    var id: Self { self }

    var statsArguments: [String] {
        switch self {
        case .today: ["--days", "0"]
        case .week: ["--days", "7"]
        case .month: ["--days", "30"]
        case .lifetime: ["--all"]
        }
    }
}
