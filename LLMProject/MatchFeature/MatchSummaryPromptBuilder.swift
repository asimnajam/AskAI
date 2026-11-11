//
//  MatchSummaryPromptBuilder.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 05/11/2026.
//

import Foundation
import LLMKit

struct MatchSummaryPromptBuilder {
    let promptStore: PromptStore
    
    func build(for match: Match) async throws -> LLMPrompt {
        let template = try await promptStore.template(for: PromptID.matchSummary.rawValue)
        let system = try template.rendered(with: ["allowed_players": match.allPlayers.joined(separator: ", ")])
        
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let matchJSON = String(decoding: try jsonEncoder.encode(match), as: UTF8.self)
        let user = "<match_data>\n\(matchJSON)\n</match_data>"
        
        return LLMPrompt(
            system: system,
            user: user,
            promptID: template.id,
            promptVersion: template.version
        )
    }
}
