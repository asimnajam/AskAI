//
//  MatchStore.swift
//  LLMProject
//

import Foundation

/// Loads the sample matches bundled with the app (MatchFeature/Resources/matches.json).
struct MatchStore {
    enum StoreError: Error, Equatable {
        case fileNotFound
    }

    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    /// All matches, newest first.
    func loadMatches() throws -> [Match] {
        guard let url = bundle.url(forResource: "matches", withExtension: "json") else {
            throw StoreError.fileNotFound
        }
        let data = try Data(contentsOf: url)
        let matches = try JSONDecoder().decode([Match].self, from: data)
        // ISO dates ("2026-11-09") sort correctly as plain strings.
        return matches.sorted { $0.date > $1.date }
    }
}
