import Foundation
import Testing
@testable import CodexBarCore

struct FableUsageFetcherTests {
    @Test
    func `parses limits and leaderboard payloads into snapshot`() throws {
        let limits: [String: Any] = [
            "ok": true,
            "updated_at": "2026-07-06T22:29:33.750269+00:00",
            "source": "claude-oauth@Mac",
            "limits": [
                "five_hour": 13,
                "seven_day": 18.0,
                "five_hour_resets_at": "2026-07-07T02:29:59.666617+00:00",
                "seven_day_resets_at": "2026-07-10T12:59:59.666638+00:00",
            ] as [String: Any],
        ]
        let board: [String: Any] = [
            "ok": true,
            "rows": [
                ["model": "gpt-5.5", "runtime": "codex", "tokens": 5_694_714, "sessions": 2],
                ["model": "claude-opus-4-8", "runtime": "claude-code", "tokens": 1_051_903, "sessions": 3],
            ] as [[String: Any]],
        ]

        let snapshot = try FableUsageFetcher.parse(limits: limits, board: board)
        #expect(snapshot.fiveHourUsedPercent == 13)
        #expect(snapshot.weeklyUsedPercent == 18)
        #expect(snapshot.fiveHourResetsAt != nil)
        #expect(snapshot.leaderboard.count == 2)
        #expect(snapshot.leaderboard[0].model == "gpt-5.5")
        #expect(snapshot.leaderboardSummary?.contains("👑 gpt-5.5 5.7M") == true)

        let usage = snapshot.toUsageSnapshot()
        #expect(usage.primary?.usedPercent == 13)
        #expect(usage.secondary?.usedPercent == 18)
        #expect(usage.identity?.loginMethod?.contains("opus-4-8") == true)
    }

    @Test
    func `missing limits produce empty windows without crashing`() throws {
        let snapshot = try FableUsageFetcher.parse(limits: [:], board: [:])
        #expect(snapshot.fiveHourUsedPercent == nil)
        #expect(snapshot.leaderboard.isEmpty)
        #expect(snapshot.toUsageSnapshot().primary == nil)
    }

    @Test
    func `base url override comes from environment`() {
        #expect(FableUsageFetcher.baseURL(environment: [:]) == FableUsageFetcher.defaultBaseURL)
        #expect(FableUsageFetcher.baseURL(environment: ["FABLE_API_BASE": "https://x.example/"]) == "https://x.example")
    }
}
