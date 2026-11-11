//
//  PromptTemplateTests.swift
//  LLMKit
//
//  Created by Syed Asim Najam on 11/11/2026.
//

import Testing
import Foundation
@testable import LLMKit

struct PromptTemplateTests {
    @Test
    func validPrompt() async throws {
        let markdownPrompt = """
            ---
            id: match_summary
            version: 1
            ---
            You write short, factual match summaries for a football app.
            """
        let promptTemplate = try PromptTemplate.parse(markdownPrompt)
        
        #expect(promptTemplate.id == "match_summary")
        #expect(promptTemplate.version == 1)
        #expect(promptTemplate.text == "You write short, factual match summaries for a football app.")
        
    }

    @Test
    func noFrontMatter() async throws {
        let markdownPrompt = """
            id: match_summary
            version: 1
            ---
            You write short, factual match summaries for a football app.
            """
        
        #expect(throws: PromptError.missingFrontMatter) {
            try PromptTemplate.parse(markdownPrompt)
        }
    }
    
    @Test
    func missingVersion() async throws {
        let markdownPrompt = """
            ---
            id: match_summary
            ---
            You write short, factual match summaries for a football app.
            """
        #expect(throws: PromptError.missingField("version")) {
            try PromptTemplate.parse(markdownPrompt)
        }
    }
    
    @Test
    func missingId() async throws {
        let markdownPrompt = """
            ---
            version: 1
            ---
            You write short, factual match summaries for a football app.
            """
        #expect(throws: PromptError.missingField("id")) {
            try PromptTemplate.parse(markdownPrompt)
        }
    }
    
    @Test
    func replacePlaceholder() async throws {
        let markdownPrompt = """
            ---
            id: match_summary
            version: 1
            ---
            best player is {{allowed_player}}.
            """
        let promptTemplate = try PromptTemplate.parse(markdownPrompt)
        let renderedText = try promptTemplate.rendered(with: ["allowed_player": "messi"])
        
        #expect(renderedText == "best player is messi.")
    }
    
    @Test
    func replaceSamePlaceholders() async throws {
        let markdownPrompt = """
            ---
            id: match_summary
            version: 1
            ---
            Players: {{allowed_player}}. Best player is {{allowed_player}}.
            """
        let promptTemplate = try PromptTemplate.parse(markdownPrompt)
        let renderedText = try promptTemplate.rendered(with: ["allowed_player": "messi"])
        
        #expect(renderedText == "Players: messi. Best player is messi.")
    }
    
    @Test
    func replaceMultiplePlaceholders() async throws {
        let markdownPrompt = """
            ---
            id: match_summary
            version: 1
            ---
            Players: {{allowed_player}}. Best player is {{best_player}}.
            """
        let promptTemplate = try PromptTemplate.parse(markdownPrompt)
        let renderedText = try promptTemplate.rendered(with: ["allowed_player": "messi, Saka", "best_player": "saka"])
        
        #expect(renderedText == "Players: messi, Saka. Best player is saka.")
    }
    
    @Test
    func noPlaceholders() async throws {
        let markdownPrompt = """
            ---
            id: match_summary
            version: 1
            ---
            Players: messi, Saka. Best player is saka.
            """
        let promptTemplate = try PromptTemplate.parse(markdownPrompt)
        let renderedText = try promptTemplate.rendered(with: ["allowed_player": "messi, Saka", "best_player": "saka"])
        
        #expect(renderedText == "Players: messi, Saka. Best player is saka.")
    }
    
    @Test
    func missingValue() async throws {
        let markdownPrompt = """
            ---
            id: match_summary
            version: 1
            ---
            Players: {{allowed_player}}. Best player is {{best_player}}.
            """
        let promptTemplate = try PromptTemplate.parse(markdownPrompt)
        
        #expect(throws: PromptError.missingValue("best_player")) {
            try promptTemplate.rendered(with: ["allowed_player": "messi"])
        }
    }
    
    @Test
    func withExtraKeyShouldRenderSuccessfully() async throws {
        let markdownPrompt = """
            ---
            id: match_summary
            version: 1
            ---
            best player is {{allowed_player}}.
            """
        let promptTemplate = try PromptTemplate.parse(markdownPrompt)
        let renderedText = try promptTemplate.rendered(with: ["allowed_player": "messi", "best_player": "saka"])
        
        #expect(renderedText == "best player is messi.")
    }
}
