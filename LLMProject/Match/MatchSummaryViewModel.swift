//
//  MatchSummaryViewModel.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 10/11/2026.
//

import SwiftUI
import LLMKit

@MainActor
@Observable
final class MatchSummaryViewModel {
    enum State {
        case idle
        case loading
        case loaded(MatchSummary)
        case failed(String)
    }
    let match: Match
    private(set) var state: State = .idle
    private let client: LLMProviding
    private let promptStore: PromptStore
    
    init(match: Match,
         promptStore: PromptStore = BundledPromptStore(),
         client: LLMProviding) {
        self.match = match
        self.client = client
        self.promptStore = promptStore
    }
    
    func generate() async {
        guard case .idle = state else { return }
        state = .loading
        do {
            let prompt = try await MatchSummaryPromptBuilder(promptStore: promptStore)
                .build(for: .sample)

            let response = try await client.complete(
                prompt,
                schemaJSON: MatchSummary.schemaJSON(for: .sample),
                temperature: 0.2
            )
            print("📦 \(response.content)")

            let summary = try MatchSummary.decode(from: response.content)
            try summary.validate(against: .sample)
            state = .loaded(summary)
            print("✅ Valid summary: \(summary.headline)")
        } catch {
            state = .failed(error.localizedDescription)
            print("❌ \(error)")
        }
    }
}
