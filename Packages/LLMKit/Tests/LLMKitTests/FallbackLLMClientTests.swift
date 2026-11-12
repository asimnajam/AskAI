//
//  FallbackLLMClientTests.swift
//  LLMKitTests
//

import Testing
import Foundation
@testable import LLMKit

struct FallbackLLMClientTests {

    private let prompt = LLMPrompt(system: "system", user: "user", promptID: "test", promptVersion: 1)

    private func ok(_ text: String) -> MockLLMClient {
        MockLLMClient(behavior: .respond(text), delay: .zero)
    }

    private func failing(_ error: LLMError) -> MockLLMClient {
        MockLLMClient(behavior: .fail(error), delay: .zero)
    }

    private func collect(_ stream: AsyncThrowingStream<String, Error>) async throws -> String {
        var text = ""
        for try await chunk in stream { text += chunk }
        return text.trimmingCharacters(in: .whitespaces)
    }

    // MARK: complete

    @Test func completeUsesPrimaryWhenItWorks() async throws {
        let client = FallbackLLMClient(primary: ok("primary"), fallback: ok("fallback"))

        let response = try await client.complete(prompt, schemaJSON: nil, temperature: nil)

        #expect(response.content == "primary")
    }

    @Test func completeUsesFallbackWhenPrimaryFails() async throws {
        let client = FallbackLLMClient(
            primary: failing(.http(status: 503, model: "gemini")),
            fallback: ok("fallback")
        )

        let response = try await client.complete(prompt, schemaJSON: nil, temperature: nil)

        #expect(response.content == "fallback")
    }

    @Test func completeThrowsPrimaryErrorWhenBothFail() async {
        let client = FallbackLLMClient(
            primary: failing(.http(status: 503, model: "gemini")),
            fallback: failing(.invalidResponse)
        )

        await #expect(throws: LLMError.http(status: 503, model: "gemini")) {
            try await client.complete(prompt, schemaJSON: nil, temperature: nil)
        }
    }

    // MARK: stream

    @Test func streamUsesPrimaryWhenItWorks() async throws {
        let client = FallbackLLMClient(primary: ok("from primary"), fallback: ok("from fallback"))

        let text = try await collect(client.stream([], system: "s"))

        #expect(text == "from primary")
    }

    @Test func streamUsesFallbackWhenPrimaryFailsBeforeAnyText() async throws {
        let client = FallbackLLMClient(
            primary: failing(.http(status: 429, model: "gemini")),
            fallback: ok("from fallback")
        )

        let text = try await collect(client.stream([], system: "s"))

        #expect(text == "from fallback")
    }

    @Test func streamThrowsPrimaryErrorWhenBothFail() async {
        let client = FallbackLLMClient(
            primary: failing(.http(status: 429, model: "gemini")),
            fallback: failing(.invalidResponse)
        )

        await #expect(throws: LLMError.http(status: 429, model: "gemini")) {
            _ = try await collect(client.stream([], system: "s"))
        }
    }

    // MARK: policy

    @Test func cancellationNeverFallsBack() {
        #expect(!FallbackLLMClient.shouldFallBack(after: CancellationError()))
        #expect(!FallbackLLMClient.shouldFallBack(after: URLError(.cancelled)))
    }

    @Test func otherErrorsFallBack() {
        #expect(FallbackLLMClient.shouldFallBack(after: URLError(.notConnectedToInternet)))
        #expect(FallbackLLMClient.shouldFallBack(after: LLMError.http(status: 503, model: "gemini")))
    }
}
