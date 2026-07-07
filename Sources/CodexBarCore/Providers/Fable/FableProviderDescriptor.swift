import Foundation

public enum FableProviderDescriptor {
    public static let descriptor: ProviderDescriptor = Self.makeDescriptor()

    static func makeDescriptor() -> ProviderDescriptor {
        ProviderDescriptor(
            id: .fable,
            metadata: ProviderMetadata(
                id: .fable,
                displayName: "Fable",
                sessionLabel: "5h block",
                weeklyLabel: "Weekly",
                opusLabel: nil,
                supportsOpus: false,
                supportsCredits: false,
                creditsHint: "",
                toggleTitle: "Show Fable fleet usage",
                cliName: "fable",
                defaultEnabled: false,
                isPrimaryProvider: false,
                usesAccountFallback: false,
                browserCookieOrder: nil,
                dashboardURL: "https://visual.organizedai.vip/fable",
                statusPageURL: nil),
            branding: ProviderBranding(
                iconStyle: .fable,
                iconResourceName: "ProviderIcon-fable",
                color: ProviderColor(red: 1.0, green: 0.47, blue: 0.29)),
            tokenCost: ProviderTokenCostConfig(
                supportsTokenCost: false,
                noDataMessage: { "Fable fleet cost lives on the dashboard: visual.organizedai.vip/fable" }),
            fetchPlan: ProviderFetchPlan(
                sourceModes: [.auto, .api],
                pipeline: ProviderFetchPipeline(resolveStrategies: { _ in [FableAPIFetchStrategy()] })),
            cli: ProviderCLIConfig(
                name: "fable",
                versionDetector: nil))
    }
}

struct FableAPIFetchStrategy: ProviderFetchStrategy {
    let id: String = "fable.api"
    let kind: ProviderFetchKind = .api

    func isAvailable(_: ProviderFetchContext) async -> Bool { true }

    func fetch(_ context: ProviderFetchContext) async throws -> ProviderFetchResult {
        let snapshot = try await FableUsageFetcher.fetch(environment: context.env)
        return self.makeResult(usage: snapshot.toUsageSnapshot(), sourceLabel: "api")
    }

    func shouldFallback(on _: Error, context _: ProviderFetchContext) -> Bool { false }
}
