//
//  MatchFilterChipsTests.swift
//  LLMProjectTests
//

import Testing
@testable import LLMProject

struct MatchFilterChipsTests {

    @Test func chipsFollowFieldOrder() {
        let filters = MatchFilters(team: "Liverpool", venue: .away, result: .loss)

        #expect(filters.chips.map(\.label) == ["Liverpool", "Away", "Loss"])
    }

    @Test func emptyFiltersHaveNoChips() {
        #expect(MatchFilters().chips.isEmpty)
    }

    @Test(arguments: zip(
        [
            MatchFilters(competition: "Serie A"),
            MatchFilters(venue: .home),
            MatchFilters(result: .draw),
            MatchFilters(scorer: "Kane"),
            MatchFilters(bothTeamsScored: true),
            MatchFilters(bothTeamsScored: false),
            MatchFilters(hasRedCard: true),
            MatchFilters(hasRedCard: false),     // false is still a filter, so it gets a chip
            MatchFilters(minTotalGoals: 4),
        ],
        [
            "Serie A", "Home", "Draw", "Kane scored",
            "Both teams scored", "Not both scored",
            "Red card", "No red card", "4+ goals",
        ]
    ))
    func eachFilterHasAReadableLabel(filters: MatchFilters, expected: String) {
        #expect(filters.chips.map(\.label) == [expected])
    }

    @Test func removingAFieldKeepsTheRest() {
        let filters = MatchFilters(team: "Liverpool", venue: .away)

        #expect(filters.removing(.venue) == MatchFilters(team: "Liverpool"))
    }

    @Test(arguments: MatchFilters.Field.allCases)
    func removingEveryFieldFromAFullFilterClearsIt(field: MatchFilters.Field) {
        // Each field must be removable; a missing case in `removing` would leave it set.
        let full = MatchFilters(
            team: "x", competition: "x", venue: .home, result: .win, scorer: "x",
            bothTeamsScored: true, hasRedCard: true, minTotalGoals: 1
        )
        let removed = full.removing(field)

        #expect(removed.chips.count == full.chips.count - 1)
        #expect(!removed.chips.contains { $0.field == field })
    }
}
