import Foundation
@testable import ClaudeMeter

actor SessionKeyImportServiceStub: SessionKeyImportServiceProtocol {
    let sources: [SessionKeyImportSource]
    let result: Result<ImportedSessionKey, Error>
    private(set) var requestedSources: [SessionKeyImportSource] = []

    init(sources: [SessionKeyImportSource] = [], result: Result<ImportedSessionKey, Error>) {
        self.sources = sources
        self.result = result
    }

    func availableSources() async -> [SessionKeyImportSource] {
        sources
    }

    func importSessionKey(from source: SessionKeyImportSource) async throws -> ImportedSessionKey {
        requestedSources.append(source)
        switch result {
        case .success(let imported):
            return imported
        case .failure(let error):
            throw error
        }
    }
}
