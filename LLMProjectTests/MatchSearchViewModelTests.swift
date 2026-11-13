//
//  MatchSearchViewModelTests.swift
//  LLMProjectTests
//

import Testing
import Foundation
import LLMKit
@testable import LLMProject

@MainActor
struct MatchSearchViewModelTests {

    private static let allMatches: [Match] = (try? MatchStore().loadMatches()) ?? []

    private func makeViewModel(_ behavior: MockLLMClient.Behavior) -> MatchSearchViewModel {
        MatchSearchViewModel(
            matches: Self.allMatches,
            client: MockLLMClient(behavior: behavior, delay: .zero)
        )
    }

    private func ids(_ viewModel: MatchSearchViewModel) -> [String] {
        viewModel.results.map(\.id).sorted()
    }

    // MARK: AI search

    @Test func validAIFiltersAreApplied() async {
        let viewModel = makeViewModel(.respond(#"{"team": "Liverpool"}"#))
        viewModel.query = "Liverpool games"

        await viewModel.search()

        #expect(viewModel.mode == .ai(MatchFilters(team: "Liverpool")))
        #expect(ids(viewModel) == ["liv-mci-2026-11-02"])
        #expect(!viewModel.isSearching)
    }

    // MARK: Keyword fallback

    @Test func networkErrorFallsBackToKeywordSearch() async {
        let viewModel = makeViewModel(.fail(.http(status: 503, model: "gemini")))
        viewModel.query = "Liverpool"

        await viewModel.search()

        #expect(viewModel.mode == .keyword)
        #expect(ids(viewModel) == ["liv-mci-2026-11-02"])
    }

    @Test func emptyAIFiltersMeanNotUnderstood() async {
        // The AI returns {} for non-searches; that must not show every match.
        let viewModel = makeViewModel(.respond("{}"))
        viewModel.query = "best pizza in town"

        await viewModel.search()

        #expect(viewModel.mode == .keyword)
        #expect(viewModel.results.isEmpty)
    }

    @Test func unknownNameFromAIFallsBackToKeywordSearch() async {
        // e.g. the on-device fallback, which ignores the schema, invents a team.
        let viewModel = makeViewModel(.respond(#"{"team": "Messi FC"}"#))
        viewModel.query = "Messi FC games"

        await viewModel.search()

        #expect(viewModel.mode == .keyword)
        #expect(viewModel.results.isEmpty)
    }

    @Test func invalidJSONFallsBackToKeywordSearch() async {
        let viewModel = makeViewModel(.respond("not json"))
        viewModel.query = "Kane, Bundesliga"

        await viewModel.search()

        #expect(viewModel.mode == .keyword)
        #expect(ids(viewModel) == ["bay-bvb-2026-11-08"])
    }

    // MARK: Empty query and clear

    @Test func blankQueryShowsAllMatchesWithoutSearching() async {
        let viewModel = makeViewModel(.respond(#"{"team": "Liverpool"}"#))
        viewModel.query = "   "

        await viewModel.search()

        #expect(viewModel.mode == .none)
        #expect(viewModel.results.count == Self.allMatches.count)
    }

    @Test func clearResetsEverything() async {
        let viewModel = makeViewModel(.respond(#"{"team": "Liverpool"}"#))
        viewModel.query = "Liverpool"
        await viewModel.search()

        viewModel.clear()

        #expect(viewModel.mode == .none)
        #expect(viewModel.query.isEmpty)
        #expect(viewModel.results.count == Self.allMatches.count)
    }

    // MARK: Removing chips

    @Test func removingAChipRefiltersWithoutCallingTheAI() async {
        // City played away and won at Liverpool. Remove "Away" → all City wins.
        let viewModel = makeViewModel(
            .respond(#"{"team": "Manchester City", "venue": "away", "result": "win"}"#)
        )
        viewModel.query = "City away wins"
        await viewModel.search()

        viewModel.remove(.venue)

        #expect(viewModel.mode == .ai(MatchFilters(team: "Manchester City", result: .win)))
        #expect(ids(viewModel) == ["liv-mci-2026-11-02"])
    }

    @Test func removingTheLastChipClearsTheSearch() async {
        let viewModel = makeViewModel(.respond(#"{"hasRedCard": true}"#))
        viewModel.query = "red cards"
        await viewModel.search()
        #expect(ids(viewModel) == ["ars-che-2026-10-18", "int-juv-2026-11-09"])

        viewModel.remove(.hasRedCard)

        #expect(viewModel.mode == .none)
        #expect(viewModel.results.count == Self.allMatches.count)
    }
}
