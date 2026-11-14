//
//  LatencyMeasuringClientTests.swift
//  LLMKitTests
//

import Testing
import Foundation
@testable import LLMKit

/// Collects reports from the @Sendable `report` closure, safely across threads.
private final class ReportCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [LatencyReport] = []

    func add(_ report: LatencyReport) {
        lock.withLock { stored.append(report) }
    }

    var reports: [LatencyReport] {
        lock.withLock { stored }
    }
}

struct LatencyMeasuringClientTests {

    private let prompt = LLMPrompt(system: "s", user: "u", promptID: "match_summary", promptVersion: 3)

    private func measured(_ mock: MockLLMClient, into collector: ReportCollector) -> LatencyMeasuringClient {
        LatencyMeasuringClient(wrapping: mock) { collector.add($0) }
    }

    // MARK: complete

    @Test func completeReportsTotalTimeAndLength() async throws {
        let collector = ReportCollector()
        let client = measured(MockLLMClient(behavior: .respond("Hello"), delay: .milliseconds(100)), into: collector)

        let response = try await client.complete(prompt, schemaJSON: nil, temperature: nil)

        #expect(response.content == "Hello")              // passed through unchanged
        let report = try #require(collector.reports.first)
        #expect(collector.reports.count == 1)
        #expect(report.kind == .complete)
        #expect(report.label == "match_summary v3")
        #expect(report.total >= .milliseconds(100))
        #expect(report.characters == 5)
        #expect(report.outcome == .succeeded)
        #expect(report.timeToFirstToken == nil)
    }

    @Test func completeFailureIsReportedAndErrorIsRethrown() async throws {
        let collector = ReportCollector()
        let client = measured(MockLLMClient(behavior: .fail(.invalidResponse), delay: .zero), into: collector)

        await #expect(throws: LLMError.invalidResponse) {
            try await client.complete(prompt, schemaJSON: nil, temperature: nil)
        }

        let report = try #require(collector.reports.first)
        #expect(report.outcome == .failed)
        #expect(report.characters == 0)
    }

    // MARK: stream

    @Test func streamReportsTimeToFirstTokenBeforeTotal() async throws {
        let collector = ReportCollector()
        let client = measured(MockLLMClient(behavior: .respond("one two three"), delay: .zero), into: collector)

        var text = ""
        for try await chunk in client.stream([], system: "s") { text += chunk }

        #expect(text.trimmingCharacters(in: .whitespaces) == "one two three")   // passed through unchanged
        let report = try #require(collector.reports.first)
        let firstToken = try #require(report.timeToFirstToken)
        #expect(report.kind == .stream)
        #expect(firstToken < report.total)       // mock sends 3 words, 80 ms apart
        #expect(report.characters == text.count)
        #expect(report.outcome == .succeeded)
    }

    @Test func streamFailureIsReported() async throws {
        let collector = ReportCollector()
        let client = measured(MockLLMClient(behavior: .fail(.invalidResponse), delay: .zero), into: collector)

        await #expect(throws: LLMError.invalidResponse) {
            for try await _ in client.stream([], system: "s") {}
        }

        let report = try #require(collector.reports.first)
        #expect(report.outcome == .failed)
        #expect(report.timeToFirstToken == nil)   // no text ever arrived
    }

    // MARK: formatting

    @Test func descriptionIsReadable() {
        let report = LatencyReport(
            kind: .stream, label: "stream",
            timeToFirstToken: .milliseconds(410), total: .milliseconds(2100),
            characters: 486, outcome: .succeeded
        )
        #expect(report.description == "⏱️ stream · first token 0.41 s · total 2.10 s · 486 chars")
    }

    @Test func failedReportSaysSo() {
        let report = LatencyReport(kind: .complete, label: "match_search v1",
                                   total: .milliseconds(920), characters: 0, outcome: .failed)
        #expect(report.description == "⏱️ match_search v1 · total 0.92 s · 0 chars · failed")
    }
}
