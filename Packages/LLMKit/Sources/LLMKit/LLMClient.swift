//
//  LLMClient.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 04/11/2026.
//

import Foundation

/// Talks to any OpenAI-compatible chat API (Gemini, OpenAI, Ollama...).
public struct LLMClient: Sendable {
    let endpoint: URL
    let apiKey: String
    let timeout: TimeInterval
    /// Tried in order. If a model is retired (404), rate-limited (429)
    /// or overloaded (503), the next one is used.
    let models: [String]
    
    public init(endpoint: URL, apiKey: String, timeout: TimeInterval, models: [String]) {
        self.endpoint = endpoint
        self.apiKey = apiKey
        self.timeout = timeout
        self.models = models
    }
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
    
    private struct Completion: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable { let content: String? }
            let message: Message
        }
        let choices: [Choice]
    }
}

extension LLMClient {
    // MARK: - Public API
    private func openConnection(_ makeRequest: (String) throws -> URLRequest) async throws -> (bytes: URLSession.AsyncBytes, model: String) {
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
                return (bytes, model)
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
        temperature: Double? = nil,
        schemaJSON: String? = nil
    ) throws -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
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
        
        if let schemaJSON {
            // turns it into a dictionary
            let schema = try JSONSerialization.jsonObject(with: Data(schemaJSON.utf8))
            
            body["response_format"] = [
                "type": "json_schema",
                "json_schema": [
                    "name": "response",
                    "schema": schema,
                ],
            ]
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
}

extension LLMClient: LLMProviding {
    public func stream(_ history: [ChatMessage], system: String) -> AsyncThrowingStream<String, Error> {
        // The model has no memory: the whole conversation is sent every time.
        let messages = [
            ["role": "system", "content": system]
        ] + history.map { ["role": $0.role.rawValue, "content": $0.text] }

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let (bytes, _) = try await openConnection { model in
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
    
    public func complete(
        _ prompt: LLMPrompt,
        schemaJSON: String? = nil,
        temperature: Double? = nil
    ) async throws -> LLMResponse {
        // 1. What to send: instructions + data
        let messages = [
            ["role": "system", "content": prompt.system],
            ["role": "user", "content": prompt.user],
        ]
        
        // 2. Try models until one answers. This time keep the model name too.
        let (bytes, model) = try await openConnection { model in
            try makeRequest(
                model: model,
                messages: messages,
                stream: false,              // ← one complete answer, not pieces
                temperature: temperature,
                schemaJSON: schemaJSON
            )
        }
        
        // 3. Collect the whole response
        var data = Data()
        for try await byte in bytes {
            data.append(byte)
        }
        
        // 4. Unpack the envelope: choices[0].message.content
        let completion = try JSONDecoder().decode(Completion.self, from: data)
        guard let content = completion.choices.first?.message.content else {
            throw LLMError.invalidResponse
        }
        
        // 5. Log which prompt and model produced this answer
        print("📝 \(prompt.promptID) v\(prompt.promptVersion) · \(model)")
        
        return LLMResponse(content: content, model: model)
    }
}
