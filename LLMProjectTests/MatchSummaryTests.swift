//
//  MatchSummaryTests.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 05/11/2026.
//

import Testing
@testable import LLMProject

struct MatchSummaryTests {
    @Test
    func decodesValidJSON() throws {
        // Arrange
        let text = """
            {"headline": "Arsenal edge Chelsea",
                     "bullets": ["a", "b", "c"],
                     "keyStat": "Arsenal had 16 shots.",
                     "playerOfTheMatch": "Saka"}
            """
        // Act
        let matchSummary = try MatchSummary.decode(from: text)
        
        // Assert
        #expect(matchSummary.headline == "Arsenal edge Chelsea")
        #expect(matchSummary.bullets == ["a", "b", "c"])
        #expect(matchSummary.keyStat == "Arsenal had 16 shots.")
        #expect(matchSummary.playerOfTheMatch == "Saka")
    }
    
    @Test
    func decodesJSONInsideMarkdownFences() throws {
        // Arrange
        let text = """
            ```json
            {"headline": "Arsenal edge Chelsea",
                     "bullets": ["a", "b", "c"],
                     "keyStat": "Arsenal had 16 shots.",
                     "playerOfTheMatch": "Saka"}
            ```
            """
        // Act
        let matchSummary = try MatchSummary.decode(from: text)
        
        // Assert
        #expect(matchSummary.headline == "Arsenal edge Chelsea")
        #expect(matchSummary.bullets == ["a", "b", "c"])
        #expect(matchSummary.keyStat == "Arsenal had 16 shots.")
        #expect(matchSummary.playerOfTheMatch == "Saka")
    }
    
    @Test
    func throwsOnNonJSONText() throws {
        // Arrange
        let text = "Sure! here it is."
        
        #expect(throws: SummaryError.self) {
            try MatchSummary.decode(from: text)
        }
    }
    
    @Test
    func validSummaryPoints() throws {
        // Arrange
        let text = """
            {"headline": "Arsenal edge Chelsea",
                     "bullets": ["a", "b", "c"],
                     "keyStat": "Arsenal had 16 shots.",
                     "playerOfTheMatch": "Saka"}
            """
        // Act
        let matchSummary = try MatchSummary.decode(from: text)
        
        let stats = Match.Stats(
            possession: Match.TeamStat(home: 0, away: 0),
            shots: .init(home: 0, away: 0),
            shotsOnTarget: .init(home: 0, away: 0),
            corners: .init(home: 0, away: 0)
        )
        let match = Match(competition: "", date: "", homeTeam: "", awayTeam: "", homeScore: 0, awayScore: 0, homeSquad: ["Saka", "Ronaldo"], awaySquad: [], events: [], stats: stats)
        
        #expect(throws: Never.self) {
            try matchSummary.validate(against: match)
        }
    }
    
    @Test
    func wrongBulletCount() throws {
        // Arrange
        let text = """
            {"headline": "Arsenal edge Chelsea",
                     "bullets": ["a", "b"],
                     "keyStat": "Arsenal had 16 shots.",
                     "playerOfTheMatch": "Saka"}
            """
        // Act
        let matchSummary = try MatchSummary.decode(from: text)
        
        let stats = Match.Stats(
            possession: Match.TeamStat(home: 0, away: 0),
            shots: .init(home: 0, away: 0),
            shotsOnTarget: .init(home: 0, away: 0),
            corners: .init(home: 0, away: 0)
        )
        let match = Match(competition: "", date: "", homeTeam: "", awayTeam: "", homeScore: 0, awayScore: 0, homeSquad: ["Saka", "Ronaldo"], awaySquad: [], events: [], stats: stats)
        
        #expect(throws: SummaryError.wrongBulletCount(matchSummary.bullets.count)) {
            try matchSummary.validate(against: match)
        }
    }
    
    @Test
    func bulletTooLong() async throws {
        // Arrange
        let text = """
            {"headline": "Arsenal edge Chelsea",
                     "bullets": ["Ensuring uploads or file selections match expected formats (e.g., checking if an image ends with. Ensuring uploads or file selections match expected formats (e.g., checking if an image ends with", "b", "c"],
                     "keyStat": "Arsenal had 16 shots.",
                     "playerOfTheMatch": "Saka"}
            """
        // Act
        let matchSummary = try MatchSummary.decode(from: text)
        
        let stats = Match.Stats(
            possession: Match.TeamStat(home: 0, away: 0),
            shots: .init(home: 0, away: 0),
            shotsOnTarget: .init(home: 0, away: 0),
            corners: .init(home: 0, away: 0)
        )
        let match = Match(competition: "", date: "", homeTeam: "", awayTeam: "", homeScore: 0, awayScore: 0, homeSquad: ["Saka", "Ronaldo"], awaySquad: [], events: [], stats: stats)
        
        #expect(throws: SummaryError.bulletTooLong(matchSummary.bullets[0])) {
            try matchSummary.validate(against: match)
        }
    }
    
    @Test
    func wrongPlayerOfTheMatch() throws {
        // Arrange
        let text = """
            {"headline": "Arsenal edge Chelsea",
                     "bullets": ["a", "b", "c"],
                     "keyStat": "Arsenal had 16 shots.",
                     "playerOfTheMatch": "Messi"}
            """
        // Act
        let matchSummary = try MatchSummary.decode(from: text)
        
        let stats = Match.Stats(
            possession: Match.TeamStat(home: 0, away: 0),
            shots: .init(home: 0, away: 0),
            shotsOnTarget: .init(home: 0, away: 0),
            corners: .init(home: 0, away: 0)
        )
        let match = Match(competition: "", date: "", homeTeam: "", awayTeam: "", homeScore: 0, awayScore: 0, homeSquad: ["Saka", "Ronaldo"], awaySquad: [], events: [], stats: stats)
        
        #expect(throws: SummaryError.unknownPlayer(matchSummary.playerOfTheMatch)) {
            try matchSummary.validate(against: match)
        }
    }
}
