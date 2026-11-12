//
//  MatchSearchPromptBuilder.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 12/11/2026.
//

import LLMKit

struct MatchSearchPromptBuilder {
    let promptStore: PromptStore   // default: BundledPromptStore()
    
    init(promptStore: PromptStore = BundledPromptStore()) {
        self.promptStore = promptStore
    }

    func build(query: String, matches: [Match]) async throws -> LLMPrompt {
        let vocabulary = SearchVocabulary(matches: matches)
        let template = try await promptStore.template(for: PromptID.matchSearch.rawValue)
        let system = try template.rendered(with: [
            "teams": vocabulary.teams.joined(separator: ","),
            "competitions": vocabulary.competitions.joined(separator: ","),
            "players": vocabulary.players.joined(separator: ",")
        ])
        
        return LLMPrompt(
            system: system,
            user: "Search: \(query)",
            promptID: template.id,
            promptVersion: template.version
        )
    }
}
