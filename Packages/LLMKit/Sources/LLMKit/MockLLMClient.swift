//
//  MockLLMClient.swift
//  LLMKit
//
//  Created by Syed Asim Najam on 11/11/2026.
//

import Foundation

public struct MockLLMClient: LLMProviding {

    /// What the fake should do when called.
    public enum Behavior: Sendable {
        case respond(String)
        case fail(LLMError)     
    }

    private let behavior: Behavior
    private let delay: Duration

    public init(behavior: Behavior, delay: Duration = .milliseconds(800)) {
        self.behavior = behavior
        self.delay = delay
    }

    // Used by the match summary
    public func complete(_ prompt: LLMPrompt, schemaJSON: String?, temperature: Double?) async throws -> LLMResponse {
        try await Task.sleep(for: delay)      // pretend we're waiting for the network

        switch behavior {
        case .respond(let text):
            return LLMResponse(content: text, model: "mock")
        case .fail(let error):
            throw error
        }
    }

    // Used by the chat: sends the text word by word, like real streaming
    public func stream(_ history: [ChatMessage], system: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    switch behavior {
                    case .respond(let text):
                        for word in text.split(separator: " ") {
                            try await Task.sleep(for: .milliseconds(80))
                            continuation.yield(word + " ")
                        }
                        continuation.finish()
                    case .fail(let error):
                        try await Task.sleep(for: delay)
                        continuation.finish(throwing: error)
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
