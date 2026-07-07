import CodexBarCore
import Foundation

struct FableProviderImplementation: ProviderImplementation {
    let id: UsageProvider = .fable

    @MainActor
    func presentation(context _: ProviderPresentationContext) -> ProviderPresentation {
        ProviderPresentation { _ in "api" }
    }

    @MainActor
    func observeSettings(_: SettingsStore) {}

    @MainActor
    func isAvailable(context _: ProviderAvailabilityContext) -> Bool {
        // The Fable stack API is public read-only; the provider is deployable
        // as soon as the toggle is enabled. FABLE_API_BASE overrides the endpoint.
        true
    }

    @MainActor
    func settingsFields(context _: ProviderSettingsContext) -> [ProviderSettingsFieldDescriptor] { [] }
}
