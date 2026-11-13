//
//  MatchFilters+Chips.swift
//  LLMProject
//
//  Turns filters into short labels ("Liverpool", "Away", "4+ goals"),
//  so the user can see what the AI understood and remove parts of it.
//

import Foundation

extension MatchFilters {
    enum Field: CaseIterable, Sendable {
        case team, competition, venue, result, scorer, bothTeamsScored, hasRedCard, minTotalGoals
    }

    struct Chip: Identifiable, Equatable, Sendable {
        let field: Field
        let label: String
        var id: Field { field }
    }

    /// One chip per filter that is set, always in the order of `Field.allCases`.
    var chips: [Chip] {
        Field.allCases.compactMap { field in
            label(for: field).map { Chip(field: field, label: $0) }
        }
    }

    /// A copy with one filter removed.
    func removing(_ field: Field) -> MatchFilters {
        var copy = self
        switch field {
        case .team: copy.team = nil
        case .competition: copy.competition = nil
        case .venue: copy.venue = nil
        case .result: copy.result = nil
        case .scorer: copy.scorer = nil
        case .bothTeamsScored: copy.bothTeamsScored = nil
        case .hasRedCard: copy.hasRedCard = nil
        case .minTotalGoals: copy.minTotalGoals = nil
        }
        return copy
    }

    /// The chip text for one field, or nil when that filter isn't set.
    private func label(for field: Field) -> String? {
        switch field {
        case .team:
            return team
        case .competition:
            return competition
        case .venue:
            return venue.map { $0 == .home ? "Home" : "Away" }
        case .result:
            return result.map {
                switch $0 {
                case .win: "Win"
                case .draw: "Draw"
                case .loss: "Loss"
                }
            }
        case .scorer:
            return scorer.map { "\($0) scored" }
        case .bothTeamsScored:
            return bothTeamsScored.map { $0 ? "Both teams scored" : "Not both scored" }
        case .hasRedCard:
            return hasRedCard.map { $0 ? "Red card" : "No red card" }
        case .minTotalGoals:
            return minTotalGoals.map { "\($0)+ goals" }
        }
    }
}
