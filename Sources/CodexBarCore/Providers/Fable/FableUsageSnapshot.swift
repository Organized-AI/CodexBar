import Foundation

/// Snapshot of the Organized AI Fable stack: live Claude limits (5h window +
/// weekly cap) plus the fleet model leaderboard aggregated from Claude Code
/// JSONL, Codex sessions, and local LLM runtimes.
/// Backed by fable-cal (`/api/limits`, `/api/usage/leaderboard`).
public struct FableUsageSnapshot: Sendable {
    public struct LeaderboardRow: Sendable {
        public let model: String
        public let runtime: String
        public let tokens: Int
        public let sessions: Int

        public init(model: String, runtime: String, tokens: Int, sessions: Int) {
            self.model = model
            self.runtime = runtime
            self.tokens = tokens
            self.sessions = sessions
        }
    }

    public let fiveHourUsedPercent: Double?
    public let weeklyUsedPercent: Double?
    public let fiveHourResetsAt: Date?
    public let weeklyResetsAt: Date?
    public let leaderboard: [LeaderboardRow]
    public let updatedAt: Date

    public init(
        fiveHourUsedPercent: Double?,
        weeklyUsedPercent: Double?,
        fiveHourResetsAt: Date?,
        weeklyResetsAt: Date?,
        leaderboard: [LeaderboardRow],
        updatedAt: Date)
    {
        self.fiveHourUsedPercent = fiveHourUsedPercent
        self.weeklyUsedPercent = weeklyUsedPercent
        self.fiveHourResetsAt = fiveHourResetsAt
        self.weeklyResetsAt = weeklyResetsAt
        self.leaderboard = leaderboard
        self.updatedAt = updatedAt
    }

    static func formatTokens(_ tokens: Int) -> String {
        switch tokens {
        case 1_000_000...: return String(format: "%.1fM", Double(tokens) / 1_000_000)
        case 1_000...: return String(format: "%.0fk", Double(tokens) / 1_000)
        default: return "\(tokens)"
        }
    }

    /// Compact leaderboard summary, e.g. "👑 gpt-5.5 5.7M · opus-4-8 1.1M".
    var leaderboardSummary: String? {
        let top = self.leaderboard.prefix(2)
        guard !top.isEmpty else { return nil }
        let parts = top.enumerated().map { index, row in
            let shortModel = row.model
                .replacingOccurrences(of: "claude-", with: "")
                .replacingOccurrences(of: "-20[0-9]{6}$", with: "", options: .regularExpression)
            let prefix = index == 0 ? "👑 " : ""
            return "\(prefix)\(shortModel) \(Self.formatTokens(row.tokens))"
        }
        return parts.joined(separator: " · ")
    }

    public func toUsageSnapshot() -> UsageSnapshot {
        let session = self.fiveHourUsedPercent.map { percent in
            RateWindow(
                usedPercent: min(100, max(0, percent)),
                windowMinutes: 5 * 60,
                resetsAt: self.fiveHourResetsAt,
                resetDescription: nil)
        }
        let weekly = self.weeklyUsedPercent.map { percent in
            RateWindow(
                usedPercent: min(100, max(0, percent)),
                windowMinutes: 7 * 24 * 60,
                resetsAt: self.weeklyResetsAt,
                resetDescription: nil)
        }
        let identity = ProviderIdentitySnapshot(
            providerID: .fable,
            accountEmail: nil,
            accountOrganization: nil,
            loginMethod: self.leaderboardSummary)
        return UsageSnapshot(
            primary: session,
            secondary: weekly,
            tertiary: nil,
            providerCost: nil,
            updatedAt: self.updatedAt,
            identity: identity)
    }
}
