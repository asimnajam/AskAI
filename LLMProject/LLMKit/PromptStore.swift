//
//  PromptStore.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 05/11/2026.
//

protocol PromptStore: Sendable {
    func template(for id: String) async throws -> PromptTemplate
}
