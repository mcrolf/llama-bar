import Foundation

@Observable @MainActor
final class UsageMonitor {
    var period: UsagePeriod = .today
    private(set) var stats: UsageStats?
    private(set) var failure: String?

    func refresh() async {
        let requested = period
        do {
            let latest = try await UsageStats.read(requested)
            guard requested == period else { return }  // A newer period was picked meanwhile.
            stats = latest
            failure = nil
        } catch {
            failure = error.localizedDescription
        }
    }
}
