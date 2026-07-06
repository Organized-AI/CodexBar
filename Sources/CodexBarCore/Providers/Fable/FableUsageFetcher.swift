import Foundation

public enum FableUsageError: Error, LocalizedError {
    case badResponse(Int)
    case malformedPayload

    public var errorDescription: String? {
        switch self {
        case let .badResponse(code): "Fable API returned HTTP \(code)"
        case .malformedPayload: "Fable API payload was malformed"
        }
    }
}

/// Fetches live limits + the fleet model leaderboard from the fable-cal worker.
/// Base URL can be overridden with the FABLE_API_BASE environment variable.
public enum FableUsageFetcher {
    public static let defaultBaseURL = "https://fable-cal.jordan-691.workers.dev"

    static func baseURL(environment: [String: String]) -> String {
        let override = environment["FABLE_API_BASE"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let override, !override.isEmpty {
            return override.hasSuffix("/") ? String(override.dropLast()) : override
        }
        return self.defaultBaseURL
    }

    public static func fetch(environment: [String: String] = [:]) async throws -> FableUsageSnapshot {
        let base = self.baseURL(environment: environment)
        async let limitsData = self.getJSON("\(base)/api/limits")
        async let boardData = self.getJSON("\(base)/api/usage/leaderboard")
        let limits = try await limitsData
        let board = (try? await boardData) ?? [:]
        return try self.parse(limits: limits, board: board)
    }

    private static func getJSON(_ url: String) async throws -> [String: Any] {
        guard let requestURL = URL(string: url) else { throw FableUsageError.malformedPayload }
        var request = URLRequest(url: requestURL)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("codexbar-fable/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 20
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw FableUsageError.badResponse(http.statusCode)
        }
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FableUsageError.malformedPayload
        }
        return object
    }

    static func parse(limits: [String: Any], board: [String: Any]) throws -> FableUsageSnapshot {
        let limitValues = limits["limits"] as? [String: Any] ?? [:]
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoPlain = ISO8601DateFormatter()
        func date(_ value: Any?) -> Date? {
            guard let string = value as? String else { return nil }
            return iso.date(from: string) ?? isoPlain.date(from: string)
        }
        func percent(_ value: Any?) -> Double? {
            if let number = value as? Double { return number }
            if let number = value as? Int { return Double(number) }
            return nil
        }
        let rows = (board["rows"] as? [[String: Any]] ?? []).compactMap { row -> FableUsageSnapshot.LeaderboardRow? in
            guard let model = row["model"] as? String else { return nil }
            return FableUsageSnapshot.LeaderboardRow(
                model: model,
                runtime: row["runtime"] as? String ?? "unknown",
                tokens: row["tokens"] as? Int ?? 0,
                sessions: row["sessions"] as? Int ?? 0)
        }
        return FableUsageSnapshot(
            fiveHourUsedPercent: percent(limitValues["five_hour"]),
            weeklyUsedPercent: percent(limitValues["seven_day"]),
            fiveHourResetsAt: date(limitValues["five_hour_resets_at"]),
            weeklyResetsAt: date(limitValues["seven_day_resets_at"]),
            leaderboard: rows,
            updatedAt: date(limits["updated_at"]) ?? Date())
    }
}
