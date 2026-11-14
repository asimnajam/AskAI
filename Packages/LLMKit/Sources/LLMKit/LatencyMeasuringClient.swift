//
//  LatencyMeasuringClient.swift
//  LLMKit
//

import Foundation

/// Wraps any provider and measures how long each request takes.
/// It passes every call through unchanged; it only adds timing.
///
/// Place it outermost (around FallbackLLMClient) to measure what the user
/// experiences, including time spent on a failed attempt before a fallback answered.
public struct LatencyMeasuringClient: LLMProviding {
    private let wrapped: any LLMProviding
    private let report: @Sendable (LatencyReport) -> Void

    /// - Parameter report: where reports go. The app prints them; tests collect them.
    public init(
        wrapping wrapped: any LLMProviding,
        report: @escaping @Sendable (LatencyReport) -> Void = { print($0) }
    ) {
        self.wrapped = wrapped
        self.report = report
    }

    // MARK: - Complete

    public func complete(_ prompt: LLMPrompt, schemaJSON: String?, temperature: Double?) async throws -> LLMResponse {
        let clock = ContinuousClock()
        let start = clock.now
        let label = "\(prompt.promptID) v\(prompt.promptVersion)"

        do {
            let response = try await wrapped.complete(prompt, schemaJSON: schemaJSON, temperature: temperature)
            report(LatencyReport(
                kind: .complete,
                label: label,
                total: start.duration(to: clock.now),
                characters: response.content.count,
                outcome: .succeeded
            ))
            return response
        } catch {
            report(LatencyReport(
                kind: .complete,
                label: label,
                total: start.duration(to: clock.now),
                characters: 0,
                outcome: Self.outcome(for: error)
            ))
            throw error   // timing never changes what the caller sees
        }
    }

    // MARK: - Stream

    public func stream(_ history: [ChatMessage], system: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                let clock = ContinuousClock()
                let start = clock.now
                var timeToFirstToken: Duration?
                var characters = 0

                func send(_ outcome: LatencyReport.Outcome) {
                    report(LatencyReport(
                        kind: .stream,
                        label: "stream",
                        timeToFirstToken: timeToFirstToken,
                        total: start.duration(to: clock.now),
                        characters: characters,
                        outcome: outcome
                    ))
                }

                do {
                    for try await chunk in wrapped.stream(history, system: system) {
                        if timeToFirstToken == nil {
                            timeToFirstToken = start.duration(to: clock.now)
                        }
                        characters += chunk.count
                        continuation.yield(chunk)
                    }
                    send(Task.isCancelled ? .cancelled : .succeeded)
                    continuation.finish()
                } catch {
                    send(Self.outcome(for: error))
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Private

    private static func outcome(for error: Error) -> LatencyReport.Outcome {
        if Task.isCancelled || error is CancellationError { return .cancelled }
        if let urlError = error as? URLError, urlError.code == .cancelled { return .cancelled }
        return .failed
    }
}
