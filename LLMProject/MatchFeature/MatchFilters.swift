//
//  MatchFilters.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 12/11/2026.
//

import Foundation

struct MatchFilters: Codable, Sendable, Equatable {
    enum Venue: String, Codable, Sendable {
        case home
        case away
    }
    
    enum Result: String, Codable, Sendable {
        case win
        case draw
        case loss
    }
    
    var team: String? = nil
    var competition: String? = nil
    var venue: Venue? = nil
    var result: Result? = nil
    var scorer: String? = nil
    var bothTeamsScored: Bool? = nil
    var hasRedCard: Bool? = nil
    var minTotalGoals: Int? = nil
    
    var isEmpty: Bool {
        team == nil && competition == nil && venue == nil && result == nil
            && scorer == nil && bothTeamsScored == nil && hasRedCard == nil
            && minTotalGoals == nil
    }
}

extension MatchFilters {
    func matches(_ match: Match) -> Bool {
        // Team: must be playing, home or away.
        // `side` is where that team played (nil when no team filter is set).
        var side: Match.Side?
        if let team {
            guard let teamSide = match.side(of: team) else { return false }
            side = teamSide
        }

        if let competition,
           match.competition.caseInsensitiveCompare(competition) != .orderedSame {
            return false
        }

        // Venue only makes sense with a team: "away" for which team?
        if let venue, let side, venue.rawValue != side.rawValue {
            return false
        }

        if let result, !match.has(result, for: side) {
            return false
        }

        if let scorer,
           !match.scorers.contains(where: { $0.caseInsensitiveCompare(scorer) == .orderedSame }) {
            return false
        }

        if let bothTeamsScored,
           (match.homeScore > 0 && match.awayScore > 0) != bothTeamsScored {
            return false
        }

        if let hasRedCard, match.hasRedCard != hasRedCard {
            return false
        }

        if let minTotalGoals, match.totalGoals < minTotalGoals {
            return false
        }

        return true
    }
}
