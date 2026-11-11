//
//  LLMProviding.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 10/11/2026.
//

public protocol LLMProviding: Sendable {
    func complete(_ prompt: LLMPrompt, schemaJSON: String?, temperature: Double?) async throws -> LLMResponse
    func stream(_ history: [ChatMessage], system: String) -> AsyncThrowingStream<String, Error>
}
