//
//  PromptTemplateTests.swift
//  ShoppingAppTests
//
//  Created by Syed Asim Najam on 05/11/2026.
//

import Testing
@testable import LLMProject

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
}
