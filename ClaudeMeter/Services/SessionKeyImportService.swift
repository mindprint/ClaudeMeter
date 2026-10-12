import Foundation
import os
import SweetCookieKit

/// Imports Claude session keys from local browser cookies.
actor SessionKeyImportService: SessionKeyImportServiceProtocol {
    private static let logger = Logger(subsystem: "com.claudemeter", category: "SessionKeyImportService")

    private let cookieClient: BrowserCookieClient
    private let browserImportOrder: [Browser]

    init(
        cookieClient: BrowserCookieClient = BrowserCookieClient(),
        browserImportOrder: [Browser] = Browser.defaultImportOrder
    ) {
        self.cookieClient = cookieClient
        self.browserImportOrder = browserImportOrder
    }

    func availableSources() async -> [SessionKeyImportSource] {
        cookieStores().map { store in
            SessionKeyImportSource(id: Self.sourceID(for: store), label: store.label)
        }
    }

    func importSessionKey(from source: SessionKeyImportSource) async throws -> ImportedSessionKey {
        // Stores are looked up again rather than cached, so a profile removed since the
        // menu was built reports "not found" instead of reading a stale path.
        guard let store = cookieStores().first(where: { Self.sourceID(for: $0) == source.id }) else {
            throw SessionKeyImportError.noSessionKeyFound(source.label)
        }

        let query = BrowserCookieQuery(domains: ["claude.ai"], domainMatch: .suffix)
        let records: [BrowserCookieRecord]
        do {
            records = try cookieClient.records(matching: query, in: store)
        } catch let error as BrowserCookieError {
            Self.logger.debug("Browser cookie import failed for \(store.label): \(error.localizedDescription)")
            switch error {
            case .accessDenied:
                if store.browser == .safari {
                    throw SessionKeyImportError.safariAccessDenied
                }
                if store.browser.usesKeychainForCookieDecryption {
                    throw SessionKeyImportError.browserKeychainAccessDenied(store.browser.displayName)
                }
                throw SessionKeyImportError.accessDenied
            case .notFound, .loadFailed:
                throw SessionKeyImportError.noSessionKeyFound(source.label)
            }
        }

        guard let cookie = records.first(where: { $0.name == "sessionKey" }) else {
            throw SessionKeyImportError.noSessionKeyFound(source.label)
        }

        let sessionKey = try SessionKey(cookie.value)
        return ImportedSessionKey(
            value: sessionKey.value,
            sourceDescription: store.label
        )
    }

    /// Cookie stores for every browser profile on disk, Safari first.
    private func cookieStores() -> [BrowserCookieStore] {
        let browsers = browserImportOrder.filter { $0 == .safari }
            + browserImportOrder.filter { $0 != .safari }
        return cookieClient.stores(in: browsers)
    }

    private static func sourceID(for store: BrowserCookieStore) -> String {
        [store.browser.rawValue, store.profile.id, store.databaseURL?.path ?? ""].joined(separator: "|")
    }
}

private extension Browser {
    var usesKeychainForCookieDecryption: Bool {
        switch self {
        case .safari, .firefox, .zen:
            return false
        case .chrome, .chromeBeta, .chromeCanary,
             .arc, .arcBeta, .arcCanary,
             .chatgptAtlas,
             .chromium,
             .yandex,
             .brave, .braveBeta, .braveNightly,
             .edge, .edgeBeta, .edgeCanary,
             .helium,
             .vivaldi,
             .dia,
             .comet:
            return true
        @unknown default:
            return true
        }
    }
}
