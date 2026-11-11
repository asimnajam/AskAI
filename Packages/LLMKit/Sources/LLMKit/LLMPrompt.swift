//
//  LLMPrompt.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 05/11/2026.
//

public struct LLMPrompt: Sendable {
    let system: String       // the instructions (from match_summary.md, placeholders filled)
    let user: String         // the match data inside <match_data> tags
    let promptID: String     // "match_summary"
    let promptVersion: Int   // 1
    
    public init(system: String, user: String, promptID: String, promptVersion: Int) {
        self.system = system
        self.user = user
        self.promptID = promptID
        self.promptVersion = promptVersion
    }
}
