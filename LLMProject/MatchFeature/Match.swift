//
//  Match.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 05/11/2026.
//

import Foundation

/// The real data the AI is allowed to use. The model never "knows" the match:
/// we send these facts with every request.
struct Match: Codable, Sendable {
    enum Side: String, Codable, Sendable { case home, away }

    enum EventType: String, Codable, Sendable {
        case goal, penaltyGoal, yellowCard, redCard
    }

    struct Event: Codable, Sendable {
        let minute: Int
        let type: EventType
        let side: Side
        let player: String
        var detail: String? = nil
    }

    struct TeamStat: Codable, Sendable, Equatable {
        let home: Int
        let away: Int
    }
    
    struct Stats: Codable, Sendable {
        let possession: TeamStat
        let shots: TeamStat
        let shotsOnTarget: TeamStat
        let corners: TeamStat
    }

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
