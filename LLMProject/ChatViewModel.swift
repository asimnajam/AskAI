//
//  ChatViewModel.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 04/11/2026.
//

import Foundation
import Observation

@MainActor @Observable
final class ChatViewModel {
    var messages: [ChatMessage] = []
    var input = ""
    var isStreaming = false

    private var task: Task<Void, Never>?
    private let client = LLMClient()
    private let systemPrompt = "You are a friendly football expert. Keep answers short and clear."
//    private let systemPrompt = """
//    You are a friendly football expert. Keep answers short and clear.
//    Reply in plain text only. Do not use Markdown formatting.
//    """
    func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isStreaming else { return }

        input = ""
        messages.append(ChatMessage(role: .user, text: text))
        let history = messages
        messages.append(ChatMessage(role: .assistant, text: ""))
        isStreaming = true

        task = Task {
            do {
                for try await chunk in client.stream(history, system: systemPrompt) {
                    print("****> Chunk: \(chunk)")
                    messages[messages.count - 1].text += chunk
                }
            } catch {
                messages[messages.count - 1].text += "\n⚠️ \(error.localizedDescription)"
            }
            isStreaming = false
        }
    }

    func stop() {
        task?.cancel()
    }
}
