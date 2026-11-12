//
//  ChatAssistantPromptBuilder.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 11/11/2026.
//

import Foundation
import LLMKit

struct ChatAssistantPromptBuilder {
    let promptStore: PromptStore
    
    init(promptStore: PromptStore = BundledPromptStore()) {
        self.promptStore = promptStore
    }
    
    func build(today: Date = .now) async throws -> ChatSystemPrompt {
        let template = try await promptStore.template(for: PromptID.chatAssistant.rawValue)
        let system = try template.rendered(with: [
            "today": today.formatted(.iso8601.year().month().day())   // "2026-11-11"
        ])
        
        return ChatSystemPrompt(
            text: system,
            promptID: template.id,
            promptVersion: template.version
        )
    }
}
