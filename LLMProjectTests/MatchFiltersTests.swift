//
//  MatchFiltersTests.swift
//  LLMProjectTests
//

import Testing
import Foundation
@testable import LLMProject

struct MatchFiltersTests {

    private static let allMatches: [Match] = (try? MatchStore().loadMatches()) ?? []

    /// Ids of the matches a filter keeps, sorted so the order doesn't matter.
    private func ids(for filters: MatchFilters) -> [String] {
        Self.allMatches.filter(filters.matches).map(\.id).sorted()
    }

    // MARK: Filtering against the real sample data

    @Test(arguments: zip(
        [
            MatchFilters(team: "Liverpool"),
            MatchFilters(team: "Liverpool", result: .loss),
            MatchFilters(team: "Liverpool", result: .win),
            MatchFilters(result: .draw),
            MatchFilters(competition: "Premier League"),
            MatchFilters(bothTeamsScored: true),
            MatchFilters(hasRedCard: true),
            MatchFilters(scorer: "Kane"),
            MatchFilters(minTotalGoals: 4),
            MatchFilters(team: "Arsenal", venue: .away),
            MatchFilters(team: "liverpool"),                         // case-insensitive
            MatchFilters(team: "Manchester City", venue: .away, result: .win),
            MatchFilters(competition: "Premier League", bothTeamsScored: false),
        ],
        [
            ["liv-mci-2026-11-02"],
            ["liv-mci-2026-11-02"],
            [],
            ["mun-tot-2026-11-01", "rma-bar-2026-10-26"],
            ["ars-che-2026-10-18", "liv-mci-2026-11-02", "mun-tot-2026-11-01"],
            ["ars-che-2026-10-18", "liv-mci-2026-11-02", "psg-om-2026-10-25", "rma-bar-2026-10-26"],
            ["ars-che-2026-10-18", "int-juv-2026-11-09"],
            ["bay-bvb-2026-11-08"],
            ["bay-bvb-2026-11-08", "liv-mci-2026-11-02", "psg-om-2026-10-25", "rma-bar-2026-10-26"],
            [],
            ["liv-mci-2026-11-02"],
            ["liv-mci-2026-11-02"],
            ["mun-tot-2026-11-01"],
        ]
    ))
    func filtersSelectExpectedMatches(filters: MatchFilters, expectedIDs: [String]) {
        #expect(ids(for: filters) == expectedIDs.sorted())
    }

    @Test func emptyFiltersKeepEveryMatch() {
        let filters = MatchFilters()

        #expect(filters.isEmpty)
        #expect(ids(for: filters).count == Self.allMatches.count)
    }

    @Test func anySetFilterMakesItNonEmpty() {
        #expect(!MatchFilters(hasRedCard: false).isEmpty)   // `false` is still a filter
        #expect(!MatchFilters(minTotalGoals: 0).isEmpty)    // and so is 0
    }

    // MARK: Edge cases of the rules

    @Test func venueWithoutTeamIsIgnored() {
        #expect(ids(for: MatchFilters(venue: .away)).count == Self.allMatches.count)
    }

    @Test func winOrLossWithoutTeamIsIgnored() {
        #expect(ids(for: MatchFilters(result: .win)).count == Self.allMatches.count)
        #expect(ids(for: MatchFilters(result: .loss)).count == Self.allMatches.count)
    }

    @Test func unknownTeamMatchesNothing() {
        #expect(ids(for: MatchFilters(team: "Real Kraków FC")).isEmpty)
    }

    // MARK: Decoding (the shape the AI will produce)

    @Test func decodesPartialJSON() throws {
        // The AI only includes the filters the user mentioned.
        let json = #"{"team": "Liverpool", "result": "loss"}"#

        let filters = try JSONDecoder().decode(MatchFilters.self, from: Data(json.utf8))

        #expect(filters == MatchFilters(team: "Liverpool", result: .loss))
    }

    @Test func unknownEnumValueFailsToDecode() {
        // e.g. the AI writes "lost" instead of "loss": must fail, not silently become nil.
        let json = #"{"result": "lost"}"#

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(MatchFilters.self, from: Data(json.utf8))
        }
    }
}
