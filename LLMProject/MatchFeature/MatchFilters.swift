//
//  MatchFilters.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 12/11/2026.
//

import Foundation

struct MatchFilters: Codable, Sendable, Equatable {
    enum Venue: String, Codable, Sendable, CaseIterable {
        case home
        case away
    }
    
    enum Result: String, Codable, Sendable, CaseIterable {
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

extension MatchFilters {
    /// The JSON Schema the AI's answer must follow.
        /// Names are limited to the real ones in `vocabulary`; every field is optional.
    static func schemaJSON(vocabulary: SearchVocabulary) -> String {
        var properties: [String: Any] = [
            "venue": ["type": "string", "enum": Venue.allCases.map(\.rawValue)],
            "result": ["type": "string", "enum": Result.allCases.map(\.rawValue)],
            "bothTeamsScored": ["type": "boolean"],
            "hasRedCard": ["type": "boolean"],
            "minTotalGoals": ["type": "integar", "minimum": "0"]
        ]
        
        if !vocabulary.teams.isEmpty {
            properties["team"] = ["type": "string", "enum": vocabulary.teams]
        }
        
        if !vocabulary.competitions.isEmpty {
            properties["competitions"] = ["type": "string", "enum": vocabulary.competitions]
        }
        
        if !vocabulary.players.isEmpty {
            properties["scorer"] = ["type": "string", "enum": vocabulary.players]
        }
        
        // No "required": the model includes only what the user asked for.
        let schema: [String: Any] = ["type": "object", "properties": properties]
        
        let data = (try? JSONSerialization.data(withJSONObject: schema, options: .sortedKeys)) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }
}

extension MatchFilters {
    /// True if every name in the filters (team, competition, scorer) exists in the data.
    /// The schema already limits names, but the on-device fallback ignores the schema,
    /// so this check is the real guarantee.
    func usesOnlyKnownNames(_ vocabulary: SearchVocabulary) -> Bool {
        isKnown(team, in: vocabulary.teams)
            && isKnown(competition, in: vocabulary.competitions)
            && isKnown(scorer, in: vocabulary.players)
    }

    /// A name that isn't set (nil) is always fine; a set name must be in the list.
    private func isKnown(_ name: String?, in allowed: [String]) -> Bool {
        guard let name else { return true }
        return allowed.contains { $0.caseInsensitiveCompare(name) == .orderedSame }
    }
}
