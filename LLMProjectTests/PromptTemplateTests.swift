//
//  PromptTemplateTests.swift
//  ShoppingAppTests
//
//  Created by Syed Asim Najam on 05/11/2026.
//

import Testing
import LLMKit
import Foundation
@testable import LLMProject

struct PromptTemplateTests {
    @Test
    func bundledMatchSummaryPromptRendersCompletely() async throws {
        let template = try await BundledPromptStore().template(for: PromptID.matchSummary.rawValue)
        #expect(template.id == "match_summary")
        
        let rendered = try template.rendered(with: [
            "allowed_players": Match.sample.allPlayers.joined(separator: ", ")
        ])

        #expect(!rendered.contains("{{"))
        #expect(rendered.contains("Saka"))
    }
}
