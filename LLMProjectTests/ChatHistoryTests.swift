//
//  ChatHistoryTests.swift
//  LLMProjectTests
//

import Testing
import Foundation
import LLMKit
@testable import LLMProject

struct ChatHistoryTests {

    private func user(_ text: String) -> ChatMessage { ChatMessage(role: .user, text: text) }
    private func assistant(_ text: String) -> ChatMessage { ChatMessage(role: .assistant, text: text) }

    @Test func fewerMessagesThanLimitAreKept() {
        let messages = [user("Q1"), assistant("A1"), user("Q2")]

        let history = ChatViewModel.recentHistory(messages, limit: 10)

        #expect(history.map(\.text) == ["Q1", "A1", "Q2"])
    }

    @Test func onlyTheLastMessagesAreKept() {
        let messages = [user("Q1"), assistant("A1"), user("Q2"), assistant("A2"), user("Q3")]

        let history = ChatViewModel.recentHistory(messages, limit: 3)

        #expect(history.map(\.text) == ["Q2", "A2", "Q3"])
    }

    @Test func historyNeverStartsWithAnAssistantMessage() {
        let messages = [user("Q1"), assistant("A1"), user("Q2"), assistant("A2"), user("Q3")]

        // The last 4 start with "A1", which must be dropped.
        let history = ChatViewModel.recentHistory(messages, limit: 4)

        #expect(history.first?.role == .user)
        #expect(history.map(\.text) == ["Q2", "A2", "Q3"])
    }

    @Test func failedRepliesAreExcluded() {
        let failed = assistant(ChatViewModel.errorMessage)
        let messages = [user("Q1"), failed, user("Q2")]

        let history = ChatViewModel.recentHistory(messages, excluding: [failed.id], limit: 10)

        #expect(history.map(\.text) == ["Q1", "Q2"])
    }

    @Test func emptyRepliesAreExcluded() {
        // e.g. the user tapped Stop before any text arrived
        let messages = [user("Q1"), assistant(""), user("Q2")]

        let history = ChatViewModel.recentHistory(messages, limit: 10)

        #expect(history.map(\.text) == ["Q1", "Q2"])
    }

    @Test func emptyConversationGivesEmptyHistory() {
        #expect(ChatViewModel.recentHistory([], limit: 10).isEmpty)
    }
}
