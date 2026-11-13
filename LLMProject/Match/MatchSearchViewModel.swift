//
//  MatchSearchViewModel.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 13/11/2026.
//

import SwiftUI
import LLMKit

@MainActor @Observable
final class MatchSearchViewModel {
    enum Mode: Equatable {
        case none                     // no search: all matches
        case ai(MatchFilters)         // the AI understood: these filters were applied
        case keyword                  // fallback: plain text search
    }

    var query = ""
    private(set) var results: [Match]
    private(set) var mode: Mode = .none
    private(set) var isSearching = false

    private var searchID = 0
    private let matches: [Match]
    private let client: LLMProviding
    private let promptBuilder: MatchSearchPromptBuilder

    init(matches: [Match], client: LLMProviding, promptBuilder: MatchSearchPromptBuilder = .init()) {
        self.matches = matches
        self.client = client
        self.promptBuilder = promptBuilder
        self.results = matches        // start by showing everything
    }
}

extension MatchSearchViewModel {
    func search() async {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            clear()
            return
        }

        // Remember which search this is. If the user starts a newer one while we wait
        // for the AI, this one's (older) answer must not overwrite the newer results.
        searchID += 1
        let thisSearch = searchID

        isSearching = true
        defer {
            if thisSearch == searchID { isSearching = false }
        }

        let vocabulary = SearchVocabulary(matches: matches)

        do {
            let prompt = try await promptBuilder.build(query: text, matches: matches)
            let response = try await client.complete(
                prompt,
                schemaJSON: MatchFilters.schemaJSON(vocabulary: vocabulary),
                temperature: 0          // same search → same filters
            )
            guard thisSearch == searchID else { return }   // a newer search started

            let filters = try Self.decodeFilters(from: response.content)
            print("🔎 \"\(text)\" → \(filters)")

            if filters.isEmpty {
                // The AI didn't see a match search here (e.g. "best pizza").
                keywordSearch(text)
            } else if !filters.usesOnlyKnownNames(vocabulary) {
                // Possible when the on-device fallback answered: it ignores the schema.
                print("⚠️ Unknown name in AI filters, using keyword search")
                keywordSearch(text)
            } else {
                results = matches.filter(filters.matches)
                mode = .ai(filters)
            }
        } catch {
            guard thisSearch == searchID else { return }
            print("❌ AI search failed: \(error)")
            keywordSearch(text)
        }
    }

    /// Removes one filter chip and re-filters locally. No new AI call:
    /// we already know what the user meant, minus the part they removed.
    func remove(_ field: MatchFilters.Field) {
        guard case .ai(let current) = mode else { return }
        let filters = current.removing(field)

        if filters.isEmpty {
            clear()
        } else {
            results = matches.filter(filters.matches)
            mode = .ai(filters)
        }
    }

    func clear() {
        searchID += 1          // also cancels any search still waiting for the AI
        query = ""
        results = matches
        mode = .none
        isSearching = false
    }

    // MARK: - Private

    /// Fallback: a match is a result if every word of the query appears in its text.
    private func keywordSearch(_ text: String) {
        let words = text.lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
            .filter { $0.count >= 2 }

        results = matches.filter { match in
            let haystack = ([match.homeTeam, match.awayTeam, match.competition]
                            + match.homeSquad + match.awaySquad)
                .joined(separator: " ")
                .lowercased()
            return !words.isEmpty && words.allSatisfy(haystack.contains)
        }
        mode = .keyword
    }

    /// Some models wrap JSON in ```json fences even when told not to.
    private static func decodeFilters(from raw: String) throws -> MatchFilters {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```") {
            text = text
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return try JSONDecoder().decode(MatchFilters.self, from: Data(text.utf8))
    }
}
