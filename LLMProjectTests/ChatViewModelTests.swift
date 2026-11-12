//
//  ChatViewModelTests.swift
//  LLMProjectTests
//

import Testing
import Foundation
import LLMKit
@testable import LLMProject

@MainActor
struct ChatViewModelTests {

    // MARK: Helpers

    private func makeViewModel(_ behavior: MockLLMClient.Behavior) -> ChatViewModel {
        ChatViewModel(client: MockLLMClient(behavior: behavior, delay: .zero))
    }

    /// `send()` starts its work in a background Task, so tests wait for the result.
    /// Checks the condition every 10 ms and fails the test after the timeout.
    private func waitUntil(
        timeout: Duration = .seconds(5),
        _ condition: () -> Bool
    ) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout
        while !condition() {
            guard clock.now < deadline else {
                Issue.record("Timed out waiting for condition")
                return
            }
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    private func lastText(_ viewModel: ChatViewModel) -> String {
        (viewModel.messages.last?.text ?? "").trimmingCharacters(in: .whitespaces)
    }

    // MARK: Sending

    @Test func sendingAddsUserAndAssistantMessagesAndClearsInput() {
        let viewModel = makeViewModel(.respond("Offside explained simply."))
        viewModel.input = "What is offside?"

        viewModel.primaryActionTapped()

        // Checked immediately, before the reply arrives.
        #expect(viewModel.messages.map(\.role) == [.user, .assistant])
        #expect(viewModel.messages.first?.text == "What is offside?")
        #expect(viewModel.input.isEmpty)
        #expect(viewModel.isStreaming)
    }

    @Test func replyStreamsIntoAssistantMessage() async throws {
        let viewModel = makeViewModel(.respond("Offside explained simply."))
        viewModel.input = "What is offside?"

        viewModel.primaryActionTapped()
        try await waitUntil { !viewModel.isStreaming }

        #expect(lastText(viewModel) == "Offside explained simply.")
    }

    @Test func buttonTitleFollowsStreamingState() async throws {
        let viewModel = makeViewModel(.respond("Short answer."))
        viewModel.input = "Question"
        #expect(viewModel.primaryActionTitle == "Send")

        viewModel.primaryActionTapped()
        #expect(viewModel.primaryActionTitle == "Stop")

        try await waitUntil { !viewModel.isStreaming }
        #expect(viewModel.primaryActionTitle == "Send")
    }

    @Test func invalidInputIsNotSent() {
        let viewModel = makeViewModel(.respond("Should never appear."))
        viewModel.input = "   \n "

        viewModel.primaryActionTapped()

        #expect(viewModel.messages.isEmpty)
        #expect(!viewModel.isStreaming)
    }

    // MARK: Failure

    @Test func failingClientShowsFriendlyError() async throws {
        let viewModel = makeViewModel(.fail(.http(status: 503, model: "gemini")))
        viewModel.input = "What is offside?"

        viewModel.primaryActionTapped()
        try await waitUntil { !viewModel.isStreaming }

        #expect(lastText(viewModel) == ChatViewModel.errorMessage)
        #expect(!lastText(viewModel).contains("503"))   // no technical details for the user
    }

    // MARK: Stop

    @Test func stopKeepsPartialAnswerWithoutError() async throws {
        // Long enough that the mock (80 ms per word) is still streaming when we tap Stop.
        let longAnswer = Array(repeating: "word", count: 50).joined(separator: " ")
        let viewModel = makeViewModel(.respond(longAnswer))
        viewModel.input = "Tell me everything"

        viewModel.primaryActionTapped()
        try await waitUntil { !(viewModel.messages.last?.text.isEmpty ?? true) }   // first words arrived

        viewModel.primaryActionTapped()   // the button is now "Stop"
        try await waitUntil { !viewModel.isStreaming }

        let partial = lastText(viewModel)
        #expect(!partial.isEmpty)                            // what arrived is kept
        #expect(partial != longAnswer)                       // the rest never came
        #expect(partial != ChatViewModel.errorMessage)       // stopping is not an error
    }
}
