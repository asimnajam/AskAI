//
//  LLMClient.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 04/11/2026.
//

import Foundation

enum Role: String, Codable, Sendable {
    case user, assistant
}

struct ChatMessage: Identifiable, Sendable {
    let id = UUID()
    let role: Role
    var text: String
}

enum LLMError: LocalizedError {
    case http(status: Int, model: String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .http(let status, let model):
            "Request to \(model) failed (HTTP \(status))"
        case .invalidResponse:
            "The server sent an unexpected response"
        }
    }
}

/// Talks to any OpenAI-compatible chat API (Gemini, OpenAI, Ollama...).
struct LLMClient: Sendable {
    var endpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions")!
    var apiKey = Secrets.geminiKey

    /// Tried in order. If a model is retired (404), rate-limited (429)
    /// or overloaded (503), the next one is used.
//    var models = ["gemini-3.8-flash", "gemini-3.5-flash", "gemini-flash-lite-latest"]
    var models = ["gemini-flash-lite-latest", "gemini-3.5-flash", "gemini-3.8-flash"]
    private static let tryNextModelStatuses: Set<Int> = [404, 429, 503]

    // MARK: - Wire format

    private struct Body: Encodable {
        struct Message: Encodable {
            let role: String
            let content: String
        }
        let model: String
        let stream: Bool
        let messages: [Message]
    }

    private struct Chunk: Decodable {
        struct Choice: Decodable {
            struct Delta: Decodable { let content: String? }
            let delta: Delta
        }
        let choices: [Choice]
    }

    // MARK: - Public API

    /// Streams the assistant's reply as small pieces of text.
    func stream(_ history: [ChatMessage], system: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let bytes = try await openStream(history, system: system)
                    for try await line in bytes.lines {
                        // Server-sent events: each useful line looks like "data: {...}"
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = line.dropFirst(6)
                        if payload == "[DONE]" { break }
                        print("****> Payload: \(payload)")
                        if let chunk = try? JSONDecoder().decode(Chunk.self, from: Data(payload.utf8)),
                           let text = chunk.choices.first?.delta.content {
                            continuation.yield(text)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            // Tapping Stop cancels the consumer, which cancels the network request.
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Private

    private func openStream(_ history: [ChatMessage], system: String) async throws -> URLSession.AsyncBytes {
        var lastError: Error = LLMError.invalidResponse

        for model in models {
            let request = try makeRequest(model: model, history: history, system: system)
            let (bytes, response) = try await URLSession.shared.bytes(for: request)

            guard let http = response as? HTTPURLResponse else { throw LLMError.invalidResponse }
            if http.statusCode == 200 {
                print("✅ Using \(model)")
                return bytes
            }

            bytes.task.cancel()
            lastError = LLMError.http(status: http.statusCode, model: model)

            // 400/401 etc. mean our request or key is wrong: another model won't help.
            guard Self.tryNextModelStatuses.contains(http.statusCode) else { throw lastError }
            print("⚠️ \(model) returned \(http.statusCode), trying the next model")
        }

        throw lastError
    }

    private func makeRequest(model: String, history: [ChatMessage], system: String) throws -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // The model has no memory: the whole conversation is sent every time.
        let messages = [Body.Message(role: "system", content: system)]
            + history.map { Body.Message(role: $0.role.rawValue, content: $0.text) }

        request.httpBody = try JSONEncoder().encode(
            Body(model: model, stream: true, messages: messages)
        )
        return request
    }
}
