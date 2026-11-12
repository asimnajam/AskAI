//
//  MatchStoreTests.swift
//  LLMProjectTests
//
//  The AI can only be as accurate as the data it gets.
//  These tests check that the bundled match data is internally consistent.
//

import Testing
import Foundation
@testable import LLMProject

private final class TestBundleToken {}

struct MatchStoreTests {

    private let matches: [Match] = (try? MatchStore().loadMatches()) ?? []

    @Test func bundledMatchesLoad() throws {
        let loaded = try MatchStore().loadMatches()
        #expect(!loaded.isEmpty)
    }

    @Test func missingFileThrows() {
        let store = MatchStore(bundle: Bundle(for: TestBundleToken.self))
        #expect(throws: MatchStore.StoreError.fileNotFound) {
            try store.loadMatches()
        }
    }

    @Test func matchesAreSortedNewestFirst() {
        #expect(matches.map(\.date) == matches.map(\.date).sorted(by: >))
    }

    @Test func idsAreUnique() {
        #expect(Set(matches.map(\.id)).count == matches.count)
    }

    // MARK: Data integrity, per match

    @Test(arguments: (try? MatchStore().loadMatches()) ?? [])
    func goalEventsMatchTheScore(match: Match) {
        let goals = match.events.filter { $0.type == .goal || $0.type == .penaltyGoal }
        #expect(goals.filter { $0.side == .home }.count == match.homeScore)
        #expect(goals.filter { $0.side == .away }.count == match.awayScore)
    }

    @Test(arguments: (try? MatchStore().loadMatches()) ?? [])
    func everyEventPlayerIsInTheirTeamsSquad(match: Match) {
        for event in match.events {
            let squad = event.side == .home ? match.homeSquad : match.awaySquad
            #expect(squad.contains(event.player), "\(event.player) is not in the \(event.side) squad")
        }
    }

    @Test(arguments: (try? MatchStore().loadMatches()) ?? [])
    func possessionAddsUpTo100(match: Match) {
        #expect(match.stats.possession.home + match.stats.possession.away == 100)
    }

    @Test(arguments: (try? MatchStore().loadMatches()) ?? [])
    func eventsAreInTimeOrder(match: Match) {
        let minutes = match.events.map(\.minute)
        #expect(minutes == minutes.sorted())
    }
}
