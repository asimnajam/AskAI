//
//  ChatInputLimitTests.swift
//  LLMProjectTests
//

import Testing
import LLMKit
@testable import LLMProject

@MainActor
struct ChatInputLimitTests {

    private func makeViewModel(input: String) -> ChatViewModel {
        let viewModel = ChatViewModel(client: MockLLMClient(behavior: .respond("ok"), delay: .zero))
        viewModel.input = input
        return viewModel
    }

    @Test(arguments: [
        "",                                                         // empty
        "   \n  ",                                                  // whitespace only
        String(repeating: "a", count: ChatLimits.maxInputCharacters + 1), // one over the limit
    ])
    func cannotSendInvalidInput(input: String) {
        #expect(!makeViewModel(input: input).canSend)
    }

    @Test(arguments: [
        "What is offside?",
        String(repeating: "a", count: ChatLimits.maxInputCharacters),     // exactly at the limit
    ])
    func canSendValidInput(input: String) {
        #expect(makeViewModel(input: input).canSend)
    }

    @Test func remainingCharactersCountsDown() {
        let viewModel = makeViewModel(input: "Hello")

        #expect(viewModel.remainingCharacters == ChatLimits.maxInputCharacters - 5)
    }
}
