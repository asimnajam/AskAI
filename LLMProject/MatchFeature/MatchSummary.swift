//
//  MatchSummary.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 05/11/2026.
//

import Foundation

struct MatchSummary: Codable, Sendable {
    let headline: String
    let bullets: [String]
    let keyStat: String
    let playerOfTheMatch: String
    
    func validate(against match: Match) throws {
        guard (3...4).contains(bullets.count) else {
            throw SummaryError.wrongBulletCount(bullets.count)
        }
        
        if let long = bullets.first(where: { $0.split(separator: " ").count > 20 }) {
            throw SummaryError.bulletTooLong(long)
        }
        
        guard match.allPlayers.contains(playerOfTheMatch) else {
            throw SummaryError.unknownPlayer(playerOfTheMatch)
        }
    }
}

extension MatchSummary {
    static func decode(from raw: String) throws -> MatchSummary {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if text.hasPrefix("```") {
            text = text.replacingOccurrences(of: "```json", with: "")
            text = text.replacingOccurrences(of: "```", with: "")
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        do {
            return try JSONDecoder().decode(MatchSummary.self, from: Data(text.utf8))
        } catch {
            throw SummaryError.invalidJSON
        }
    }
    
    /// The JSON Schema sent to Gemini: the "blank form" the answer must follow.
    /// Built per match, so playerOfTheMatch can only be a player who actually played.
    static func schemaJSON(for match: Match) -> String {
        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "headline": [
                    "type": "string"
                ],
                "bullets": [
                    "type": "array",
                    "items": ["type": "string"]
                ],
                "keyStat": [
                    "type": "string"
                ],
                "playerOfTheMatch": [
                    "type": "string",
                    "enum": match.allPlayers
                ],
            ],
            "required": ["headline", "bullets", "keyStat", "playerOfTheMatch"],
        ]
        
        let data = (try? JSONSerialization.data(withJSONObject: schema)) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }
}

enum SummaryError: LocalizedError, Equatable {
    case invalidJSON
    case wrongBulletCount(Int)
    case bulletTooLong(String)
    case unknownPlayer(String)
 
    var errorDescription: String? {
        switch self {
        case .invalidJSON: "The AI returned data we couldn't read."
        case .wrongBulletCount(let n): "Expected 3 key points, got \(n)."
        case .bulletTooLong(let text): "A key point was too long: \(text)"
        case .unknownPlayer(let name): "\"\(name)\" didn't play in this match."
        }
    }
}
