//
//  Match.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 05/11/2026.
//

import Foundation

/// The real data the AI is allowed to use. The model never "knows" the match:
/// we send these facts with every request.
struct Match: Codable, Sendable, Hashable, Identifiable {
    enum Side: String, Codable, Sendable { case home, away }

    enum EventType: String, Codable, Sendable {
        case goal, penaltyGoal, yellowCard, redCard
    }

    struct Event: Codable, Sendable, Hashable {
        let minute: Int
        let type: EventType
        let side: Side
        let player: String
        var detail: String? = nil
    }

    struct TeamStat: Codable, Sendable, Hashable {
        let home: Int
        let away: Int
    }
    
    struct Stats: Codable, Sendable, Hashable {
        let possession: TeamStat
        let shots: TeamStat
        let shotsOnTarget: TeamStat
        let corners: TeamStat
    }

    /// Stable identifier, e.g. "ars-che-2026-10-18". Used for lists and navigation.
    var id: String = UUID().uuidString
    let competition: String
    let date: String
    let homeTeam: String
    let awayTeam: String
    let homeScore: Int
    let awayScore: Int
    let homeSquad: [String]
    let awaySquad: [String]
    let events: [Event]
    let stats: Stats

    var allPlayers: [String] { homeSquad + awaySquad }
}

extension Match {
    /// Fictional sample match for development.
    static let sample = Match(
        id: "ars-che-2026-10-18",
        competition: "Premier League",
        date: "2026-10-18",
        homeTeam: "Arsenal",
        awayTeam: "Chelsea",
        homeScore: 2,
        awayScore: 1,
        homeSquad: ["Raya", "Saliba", "Rice", "Ødegaard", "Saka", "Gyökeres"],
        awaySquad: ["Sánchez", "James", "Caicedo", "Fernández", "Palmer", "João Pedro"],
        events: [
            .init(minute: 23, type: .goal, side: .home, player: "Saka", detail: "Assist: Ødegaard"),
            .init(minute: 40, type: .yellowCard, side: .away, player: "Fernández"),
            .init(minute: 51, type: .penaltyGoal, side: .away, player: "Palmer"),
            .init(minute: 70, type: .redCard, side: .away, player: "Fernández", detail: "Second yellow"),
            .init(minute: 88, type: .goal, side: .home, player: "Rice", detail: "Header from a corner. Assist: Ødegaard"),
        ],
        stats: .init(
            possession: .init(home: 58, away: 42),
            shots: .init(home: 16, away: 9),
            shotsOnTarget: .init(home: 7, away: 3),
            corners: .init(home: 8, away: 3)
        )
    )
}

extension Match {
    /// Whether `team` played at home or away, or nil if it didn't play.
    func side(of team: String) -> Side? {
        if homeTeam.caseInsensitiveCompare(team) == .orderedSame { return .home }
        if awayTeam.caseInsensitiveCompare(team) == .orderedSame { return .away }
        return nil
    }

    var totalGoals: Int { homeScore + awayScore }

    var hasRedCard: Bool { events.contains { $0.type == .redCard } }

    /// Players who scored, including penalties.
    var scorers: [String] {
        events
            .filter { $0.type == .goal || $0.type == .penaltyGoal }
            .map(\.player)
    }

    /// The result from one team's point of view.
    /// Without a team, only `.draw` can be answered.
    func has(_ result: MatchFilters.Result, for side: Side?) -> Bool {
        if result == .draw { return homeScore == awayScore }
        guard let side else { return true }   // win/loss without a team: don't filter

        let (own, other) = side == .home ? (homeScore, awayScore) : (awayScore, homeScore)
        return result == .win ? own > other : own < other
    }
}
