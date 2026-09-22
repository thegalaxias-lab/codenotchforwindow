import AppKit
import Foundation
import os

/// Reads the Grok Bot weekly allowance from the same DashboardService call the
/// Grok Bot desktop app's Settings → Usage pane makes.
///
/// The bot is metered on Cursor's side — the entitlement rides a Cursor plan
/// ("Grok Bot Plan", granted to Ultra among others) — so the credential is
/// Cursor's signed-in session, borrowed exactly the way `CursorLocalProvider`
/// borrows it: the editor's store first, `cursor-agent`'s keychain login only
/// when the editor has none. One pool, one reset, one ring; nothing here is
/// shared with the Grok CLI billing endpoint the Grok card reads.
actor GrokBotProvider: UsageProvider {
    nonisolated let id = "grokbot"
    nonisolated let displayName = "Grok Bot"
    nonisolated let glyph = ProviderGlyph.grokBot

    private let endpoint =
        URL(string: "https://api2.cursor.sh/aiserver.v1.DashboardService/GetSandUsageStatus")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    nonisolated var signInRoute: SignInRoute {
        // The same door Cursor's own row opens: the session carrying the bot's
        // entitlement lives in the editor (or cursor-agent), not here.
        let installed = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: CursorCredentials.bundleID
        ) != nil
        return CursorCredentials.signInRoute(editorInstalled: installed)
    }

    nonisolated func account() -> ProviderAccount? { CursorCredentials.account() }

    nonisolated func forgetCachedCredential() { CursorCredentials.forgetCachedAgent() }

    func fetchSnapshot() async throws -> ProviderSnapshot {
        // Re-read every time, for the same reason Cursor's own provider does:
        // the editor rotates this token, and a stale copy is a sign-out.
        let credentials = try CursorCredentials.load()

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // ConnectRPC's plain-JSON protocol marker; without it the route is not
        // recognised and the call answers 404.
        request.setValue("1", forHTTPHeaderField: "Connect-Protocol-Version")
        request.httpBody = Data("{}".utf8)
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0

        if status == 401 || status == 403 {
            // A rejected token is the one signal the copy in hand is wrong
            // despite not having expired — drop the cached agent login so the
            // next read asks macOS again.
            CursorCredentials.forgetCachedAgent()
            throw UsageProviderError.needsAuth
        }
        guard (200..<300).contains(status) else {
            throw UsageProviderError.badResponse(status: status)
        }

        let body = String(data: data, encoding: .utf8) ?? ""
        Log.usage.debug("grok bot usage -> \(body.prefix(400), privacy: .public)")

        let payload = try GrokBotUsage.parse(body)
        return ProviderSnapshot(
            id: id,
            displayName: displayName,
            glyph: glyph,
            fidelity: .official,
            status: .ok,
            windows: [payload.window],
            headlineID: "bot",
            plan: payload.plan
        )
    }
}
