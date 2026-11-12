//
//  FallbackLLMClient.swift
//  LLMKit
//

import Foundation

/// Tries a primary provider first and switches to a fallback when it fails,
/// e.g. Gemini first, then Apple's on-device model.
///
/// Because it conforms to `LLMProviding` itself, features don't know
/// (or care) that there are two providers behind it.
public struct FallbackLLMClient: LLMProviding {
    private let primary: any LLMProviding
    private let fallback: any LLMProviding

    public init(primary: any LLMProviding, fallback: any LLMProviding) {
        self.primary = primary
        self.fallback = fallback
    }

    // MARK: - Complete

    public func complete(_ prompt: LLMPrompt, schemaJSON: String?, temperature: Double?) async throws -> LLMResponse {
        do {
            return try await primary.complete(prompt, schemaJSON: schemaJSON, temperature: temperature)
        } catch {
            guard Self.shouldFallBack(after: error) else { throw error }
            print("↪️ Primary failed (\(error)), trying fallback")
            let primaryError = error
            do {
                return try await fallback.complete(prompt, schemaJSON: schemaJSON, temperature: temperature)
            } catch {
                // Both failed: report the primary's error. It's usually the real cause
                // (e.g. "offline"), while the fallback's is often just "not available".
                print("❌ Fallback failed too: \(error)")
                throw primaryError
            }
        }
    }

    // MARK: - Stream

    public func stream(_ history: [ChatMessage], system: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                var receivedText = false
                do {
                    for try await chunk in primary.stream(history, system: system) {
                        receivedText = true
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                } catch {
                    // Only switch if nothing was shown yet. Switching halfway would
                    // glue two different answers together in one bubble.
                    guard !receivedText, Self.shouldFallBack(after: error) else {
                        continuation.finish(throwing: error)
                        return
                    }
                    print("↪️ Primary stream failed (\(error)), trying fallback")
                    let primaryError = error
                    do {
                        for try await chunk in fallback.stream(history, system: system) {
                            continuation.yield(chunk)
                        }
                        continuation.finish()
                    } catch {
                        print("❌ Fallback failed too: \(error)")
                        continuation.finish(throwing: primaryError)
                    }
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Policy

    /// Every failure is worth a second try, except the user stopping the request.
    static func shouldFallBack(after error: Error) -> Bool {
        if Task.isCancelled || error is CancellationError { return false }
        if let urlError = error as? URLError, urlError.code == .cancelled { return false }
        return true
    }
}
