import XCTest
@testable import Codenotch

/// Pinned to a response recorded from a live Grok Bot account — the same
/// DashboardService call the Grok Bot desktop app's Usage pane makes. The
/// route is not a published API, so this is what fails first if it changes.
final class GrokBotUsageTests: XCTestCase {
    /// Verbatim, from the account the bot's entitlement rides on.
    private let recorded = """
    {"currentPeriodStart":"2026-09-21T03:12:15.197Z",
     "nextResetTimestampUtc":"2026-09-28T03:12:15.197Z",
     "usagePercent":0.910429,
     "hasAvailableUsage":true,
     "hasNonZeroIncludedLimit":true,
     "grokPlanLabel":"Grok Bot Plan",
     "cursorPlanName":"Ultra"}
    """

    private func parse(_ json: String) throws -> GrokBotUsage.Payload {
        try GrokBotUsage.parse(json)
    }

    func testTheWeeklyMeterBecomesOneWindow() throws {
        let payload = try parse(recorded)
        let window = payload.window
        XCTAssertEqual(window.id, "bot")
        XCTAssertEqual(window.label, "Grok Bot")
        // 0.910429 on the wire is 0.91 %, not 91 %: the field is a percent
        // written as a decimal.
        XCTAssertEqual(window.usedFraction ?? -1, 0.00910429, accuracy: 1e-9)
        XCTAssertEqual(payload.plan, "Ultra")
    }

    /// The reset is the bot's own weekly boundary — Sep 28 here — independent
    /// of every Grok pool the CLI's billing endpoint meters.
    func testTheResetIsTheBotWeeklyBoundary() throws {
        let window = try parse(recorded).window
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let reset = try XCTUnwrap(window.resetsAt)
        XCTAssertEqual(calendar.component(.month, from: reset), 9)
        XCTAssertEqual(calendar.component(.day, from: reset), 28)
        // A weekly window reads as weekly: the five-hour ring logic must not
        // claim it.
        XCTAssertEqual(window.duration ?? 0, 7 * 86400, accuracy: 5)
        XCTAssertFalse(window.isFiveHour)
    }

    /// "Grok Bot Plan" → "Grok Bot". The card's title already says whose
    /// usage this is; only the plan's own name belongs on the row.
    func testThePlanSuffixIsDroppedFromTheLabel() throws {
        XCTAssertEqual(GrokBotUsage.label(from: "Grok Bot Plan"), "Grok Bot")
        XCTAssertEqual(GrokBotUsage.label(from: "SuperGrok Heavy"), "SuperGrok Heavy")
        XCTAssertEqual(GrokBotUsage.label(from: nil), "Grok Bot")
        XCTAssertEqual(GrokBotUsage.label(from: "  "), "Grok Bot")
    }

    /// An account without the entitlement answers with the field absent.
    /// That is not a reading of zero and must not become one.
    func testAnAbsentPercentIsNothingMetered() {
        let absent = #"{"hasAvailableUsage":false}"#
        XCTAssertThrowsError(try parse(absent)) { error in
            guard case UsageProviderError.nothingMetered = error else {
                return XCTFail("expected nothingMetered, got \(error)")
            }
        }
    }

    func testRejectsRubbish() {
        XCTAssertThrowsError(try parse("not json"))
    }
}
