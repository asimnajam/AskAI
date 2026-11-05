//
//  PromptStore.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 05/11/2026.
//

enum PromptID: String, CaseIterable {
    case matchSummary = "match_summary"
}

protocol PromptStore: Sendable {
    func template(for id: PromptID) async throws -> PromptTemplate
}
