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
    var timeout: TimeInterval = 20   // seconds
    
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
//    func streams(_ history: [ChatMessage], system: String) -> AsyncThrowingStream<String, Error> {
//        AsyncThrowingStream { continuation in
//            let task = Task {
//                do {
//                    let bytes = try await openStream(history, system: system)
//                    for try await line in bytes.lines {
//                        // Server-sent events: each useful line looks like "data: {...}"
//                        guard line.hasPrefix("data: ") else { continue }
//                        let payload = line.dropFirst(6)
//                        if payload == "[DONE]" { break }
//                        print("****> Payload: \(payload)")
//                        if let chunk = try? JSONDecoder().decode(Chunk.self, from: Data(payload.utf8)),
//                           let text = chunk.choices.first?.delta.content {
//                            continuation.yield(text)
//                        }
//                    }
//                    continuation.finish()
//                } catch {
//                    continuation.finish(throwing: error)
//                }
//            }
//            // Tapping Stop cancels the consumer, which cancels the network request.
//            continuation.onTermination = { _ in task.cancel() }
//        }
//    }

    // MARK: - Private

//    private func openStream(_ history: [ChatMessage], system: String) async throws -> URLSession.AsyncBytes {
//        var lastError: Error = LLMError.invalidResponse
//
//        for model in models {
//            let request = try makeRequest(model: model, history: history, system: system)
//            let (bytes, response) = try await URLSession.shared.bytes(for: request)
//
//            guard let http = response as? HTTPURLResponse else { throw LLMError.invalidResponse }
//            if http.statusCode == 200 {
//                print("✅ Using \(model)")
//                return bytes
//            }
//
//            bytes.task.cancel()
//            lastError = LLMError.http(status: http.statusCode, model: model)
//
//            // 400/401 etc. mean our request or key is wrong: another model won't help.
//            guard Self.tryNextModelStatuses.contains(http.statusCode) else { throw lastError }
//            print("⚠️ \(model) returned \(http.statusCode), trying the next model")
//        }
//
//        throw lastError
//    }
    
    private func openConnection(_ makeRequest: (String) throws -> URLRequest) async throws -> URLSession.AsyncBytes {
        var lastError: Error = LLMError.invalidResponse
        for model in models {
            let request = try makeRequest(model)
            let bytes: URLSession.AsyncBytes
            let response: URLResponse
            
            do {
                (bytes, response) = try await URLSession.shared.bytes(for: request)
            } catch let error as URLError where error.code == .timedOut {
                print("⏱️ \(model) timed out, trying the next model")
                lastError = error
                continue
            }

            guard let http = response as? HTTPURLResponse else { throw LLMError.invalidResponse }
            if http.statusCode == 200 {
                print("✅ Using \(model)")
                return bytes
            }
            
            // Read Google's error message so the console explains what went wrong.
            var errorBody = Data()
            for try await byte in bytes {
                errorBody.append(byte)
            }
            print("❌ \(model) \(http.statusCode): \(String(decoding: errorBody, as: UTF8.self))")
            lastError = LLMError.http(status: http.statusCode, model: model)
            guard Self.tryNextModelStatuses.contains(http.statusCode) else {
                throw lastError
            }
        }
        throw lastError
    }

    private func makeRequest(
        model: String,
        messages: [[String: String]],
        stream: Bool,
        temperature: Double? = nil
    ) throws -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
//        request.timeoutInterval = timeout
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "model": model,
            "stream": stream,
            "messages": messages
        ]
        if let temperature {
            body["temperature"] = temperature
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
    
    func stream(_ history: [ChatMessage], system: String) -> AsyncThrowingStream<String, Error> {
        // The model has no memory: the whole conversation is sent every time.
        let messages = [["role": "system", "content": system]]
            + history.map { ["role": $0.role.rawValue, "content": $0.text] }

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let bytes = try await openConnection { model in
                        try makeRequest(model: model, messages: messages, stream: true)
                    }
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = line.dropFirst(6)
                        if payload == "[DONE]" { break }
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
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
