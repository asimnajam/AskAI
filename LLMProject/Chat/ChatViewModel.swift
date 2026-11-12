//
//  ChatViewModel.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 04/11/2026.
//

import Foundation
import Observation
import LLMKit

@MainActor @Observable
final class ChatViewModel {
    private(set) var messages: [ChatMessage] = []
    var input = ""
    private(set) var isStreaming = false

    private var task: Task<Void, Never>?
    private let client: LLMProviding
    private let promptBuilder: ChatAssistantPromptBuilder

    /// Assistant replies that failed. They stay visible to the user,
    /// but are never sent back to the model as history.
    private var failedMessageIDs: Set<UUID> = []

    static let errorMessage = "Sorry, I couldn't answer that right now. Please try again."

    var primaryActionTitle: String {
        isStreaming ? "Stop" : "Send"
    }

    var remainingCharacters: Int {
        ChatLimits.maxInputCharacters - input.count
    }

    var canSend: Bool {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= ChatLimits.maxInputCharacters
    }

    init(client: LLMProviding, promptBuilder: ChatAssistantPromptBuilder = .init()) {
        self.client = client
        self.promptBuilder = promptBuilder
    }

    func primaryActionTapped() {
        if isStreaming {
            stop()
        } else {
            send()
        }
    }

    private func send() {
        guard canSend, !isStreaming else { return }
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)

        input = ""
        messages.append(ChatMessage(role: .user, text: text))
        let history = Self.recentHistory(
            messages,
            excluding: failedMessageIDs,
            limit: ChatLimits.maxHistoryMessages
        )

        let reply = ChatMessage(role: .assistant, text: "")
        messages.append(reply)
        isStreaming = true

        task = Task {
            do {
                let system = try await promptBuilder.build()
                print("📝 \(system.promptID) v\(system.promptVersion)")

                for try await chunk in client.stream(history, system: system.text) {
                    updateMessage(reply.id) { $0.text += chunk }
                }
            } catch is CancellationError {
                // The user tapped Stop: keep the partial answer, no error message.
            } catch {
                print("❌ Chat failed: \(error)")
                failedMessageIDs.insert(reply.id)
                updateMessage(reply.id) { $0.text = Self.errorMessage }
            }
            isStreaming = false
        }
    }

    private func stop() {
        task?.cancel()
    }

    /// Finds a message by id, so updates never land on the wrong bubble.
    private func updateMessage(_ id: UUID, _ change: (inout ChatMessage) -> Void) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        change(&messages[index])
    }
}

extension ChatViewModel {
    /// The messages to send to the model as context:
    /// - without failed replies and empty messages (e.g. stopped before any text arrived),
    /// - only the last `limit` messages,
    /// - always starting with a user message.
    nonisolated static func recentHistory(
        _ messages: [ChatMessage],
        excluding excludedIDs: Set<UUID> = [],
        limit: Int
    ) -> [ChatMessage] {
        let usable = messages.filter { message in
            !excludedIDs.contains(message.id)
                && !message.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        var recent = Array(usable.suffix(limit))
        // Conversations should start with the user, not with a cut-off assistant reply.
        while recent.first?.role == .assistant {
            recent.removeFirst()
        }
        return recent
    }
}
