//
//  SearchVocabulary.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 12/11/2026.
//

/// The names a search may use, taken from the real match data.
/// Shared by the prompt and the schema, so they always agree.
struct SearchVocabulary: Equatable {
    let teams: [String]
    let competitions: [String]
    let players: [String]

    init(matches: [Match]) {
        teams = Set(matches.flatMap { [$0.homeTeam, $0.awayTeam] }).sorted()
        competitions = Set(matches.map(\.competition)).sorted()
        players = Set(matches.flatMap { $0.homeSquad + $0.awaySquad }).sorted()
    }
}
