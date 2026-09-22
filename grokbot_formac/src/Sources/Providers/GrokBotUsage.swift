import Foundation

/// Parses the Grok Bot weekly meter, recorded from a live Grok Bot account:
///
/// `POST https://api2.cursor.sh/aiserver.v1.DashboardService/GetSandUsageStatus`
/// (ConnectRPC; Cursor's signed-in bearer token; empty JSON body):
/// ```json
/// { "currentPeriodStart": "2026-09-21T03:12:15.197Z",
///   "nextResetTimestampUtc": "2026-09-28T03:12:15.197Z",
///   "usagePercent": 0.910429,
///   "hasAvailableUsage": true, "hasNonZeroIncludedLimit": true,
///   "grokPlanLabel": "Grok Bot Plan", "cursorPlanName": "Ultra" }
/// ```
///
/// The bot's allowance is a weekly pool separate from every Grok pool the CLI's
/// billing endpoint meters, with a reset of its own — which is why it is a
/// provider of its own rather than a row on the Grok card. Two wire details
/// matter: `usagePercent` is a percent written as a decimal (0.91 means
/// 0.91 %), not the 0–1 fraction the rest of the app speaks; and an account
/// without the entitlement answers with the field simply absent, which is
/// honoured as "nothing metered" rather than dressed up as a 0 % reading.
enum GrokBotUsage {
    struct Payload {
        let window: LimitWindow
        /// The Cursor plan the entitlement rides on — "Ultra" — for the
        /// settings row. Nil when the answer does not say.
        let plan: String?
    }

    static func parse(_ json: String) throws -> Payload {
        guard let data = json.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { throw UsageProviderError.badResponse(status: 0) }

        guard let percent = root["usagePercent"] as? NSNumber else {
            let label = (root["grokPlanLabel"] as? String) ?? "Grok Bot"
            throw UsageProviderError.nothingMetered(
                L10n.t("\(label) has nothing metered on this account yet")
            )
        }

        let resetsAt = date(root["nextResetTimestampUtc"])
        let duration = date(root["currentPeriodStart"]).flatMap { start in
            resetsAt.map { $0.timeIntervalSince(start) }
        }

        return Payload(
            window: LimitWindow(
                id: "bot",
                label: label(from: root["grokPlanLabel"] as? String),
                usedFraction: min(max(percent.doubleValue / 100, 0), 1),
                resetsAt: resetsAt,
                duration: duration
            ),
            plan: (root["cursorPlanName"] as? String)?.nonEmptyPlan
        )
    }

    /// "Grok Bot Plan" → "Grok Bot": the card's title already says whose
    /// usage this is, so the row keeps only the plan's own name.
    static func label(from wire: String?) -> String {
        guard let wire = wire?.trimmingCharacters(in: .whitespaces), !wire.isEmpty else {
            return L10n.t("Grok Bot")
        }
        return wire.hasSuffix(" Plan") ? String(wire.dropLast(" Plan".count)) : wire
    }

    private static func date(_ any: Any?) -> Date? {
        guard let text = any as? String else { return nil }
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: text) { return date }
        let plain = ISO8601DateFormatter()
        return plain.date(from: text)
    }
}
