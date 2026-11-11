//
//  ChatAssistantPromptBuilderTests.swift
//  LLMProjectTests
//

import Testing
import Foundation
import LLMKit
@testable import LLMProject

/// A prompt store that returns a template we define, or throws an error we choose.
private struct FakePromptStore: PromptStore {
    var template: PromptTemplate?
    var error: PromptError?

    func template(for id: String) async throws -> PromptTemplate {
        if let error { throw error }
        return template ?? PromptTemplate(id: id, version: 1, text: "")
    }
}

/// 18 October 2026 at noon UTC: noon keeps the date the same in every time zone.
private let fixedDate: Date = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar.date(from: DateComponents(year: 2026, month: 10, day: 18, hour: 12))!
}()

struct ChatAssistantPromptBuilderTests {

    @Test func fillsTodayWithISODate() async throws {
        let store = FakePromptStore(
            template: PromptTemplate(id: "chat_assistant", version: 2, text: "Today's date is {{today}}.")
        )
        let builder = ChatAssistantPromptBuilder(promptStore: store)

        let prompt = try await builder.build(today: fixedDate)

        #expect(prompt.text == "Today's date is 2026-10-18.")
    }

    @Test func passesPromptIDAndVersionThrough() async throws {
        let store = FakePromptStore(
            template: PromptTemplate(id: "chat_assistant", version: 7, text: "Hi {{today}}")
        )
        let builder = ChatAssistantPromptBuilder(promptStore: store)

        let prompt = try await builder.build(today: fixedDate)

        #expect(prompt.promptID == "chat_assistant")
        #expect(prompt.promptVersion == 7)
    }

    @Test func storeErrorIsPassedOn() async {
        let store = FakePromptStore(error: .fileNotFound("chat_assistant"))
        let builder = ChatAssistantPromptBuilder(promptStore: store)

        await #expect(throws: PromptError.fileNotFound("chat_assistant")) {
            try await builder.build(today: fixedDate)
        }
    }

    @Test func unknownPlaceholderInTemplateThrows() async {
        // The builder only provides "today". Any other placeholder must fail, not reach the model.
        let store = FakePromptStore(
            template: PromptTemplate(id: "chat_assistant", version: 1, text: "{{today}} {{team_name}}")
        )
        let builder = ChatAssistantPromptBuilder(promptStore: store)

        await #expect(throws: PromptError.missingValue("team_name")) {
            try await builder.build(today: fixedDate)
        }
    }

    @Test func realBundledPromptRendersCompletely() async throws {
        let builder = ChatAssistantPromptBuilder(promptStore: BundledPromptStore())

        let prompt = try await builder.build(today: fixedDate)

        #expect(prompt.promptID == PromptID.chatAssistant.rawValue)
        #expect(!prompt.text.contains("{{"))
        #expect(prompt.text.contains("2026-10-18"))
    }
}
