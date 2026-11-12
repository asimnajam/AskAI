//
//  OnDeviceLLMClient.swift
//  LLMKit
//
//  Created by Syed Asim Najam on 12/11/2026.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Apple's on-device model. Free, private, works offline.
/// Needs iOS 26+ on a device (or Simulator on a Mac) with Apple Intelligence enabled.
public struct OnDeviceLLMClient: LLMProviding {

    public init() {}

    /// Whether the on-device model can be used right now.
    public static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        #endif
        return false
    }

    public func complete(_ prompt: LLMPrompt, schemaJSON: String?, temperature: Double?) async throws -> LLMResponse {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *), Self.isAvailable {
            let session = LanguageModelSession(instructions: prompt.system)
            let response = try await session.respond(to: prompt.user)
            print("📝 \(prompt.promptID) v\(prompt.promptVersion) · on-device")
            return LLMResponse(content: response.content, model: "on-device")
        }
        #endif
        throw LLMError.invalidResponse
    }

    public func stream(_ history: [ChatMessage], system: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                #if canImport(FoundationModels)
                if #available(iOS 26.0, macOS 26.0, *), Self.isAvailable {
                    do {
                        let session = LanguageModelSession(instructions: system)
                        // The model has no memory between sessions, so pass the conversation as text.
                        let conversation = history
                            .map { "\($0.role == .user ? "User" : "Assistant"): \($0.text)" }
                            .joined(separator: "\n")

                        var sent = ""
                        for try await snapshot in session.streamResponse(to: conversation) {
                            // Each snapshot is the full text so far; yield only the new part.
                            let full = snapshot.content
                            continuation.yield(String(full.dropFirst(sent.count)))
                            sent = full
                        }
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                    return
                }
                #endif
                continuation.finish(throwing: LLMError.invalidResponse)
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
