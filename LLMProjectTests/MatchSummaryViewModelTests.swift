//
//  MatchSummaryViewModelTests.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 11/11/2026.
//

import Testing
import LLMKit
@testable import LLMProject
import Foundation

@MainActor
struct MatchSummaryViewModelTests {
    private let validJSON = """
    {"headline": "Arsenal beat ten-man Chelsea",
     "bullets": ["Saka scored first.", "Palmer equalised from the spot.", "Rice headed the late winner."],
     "keyStat": "Arsenal had 16 shots to Chelsea's 9.",
     "playerOfTheMatch": "Rice"}
    """

    @Test
    func validResponseLoadsSummary() async {
        let client = MockLLMClient(behavior: .respond(validJSON), delay: .zero)
        let viewModel = MatchSummaryViewModel(match: .sample, client: client)

        await viewModel.generate()

        guard case .loaded(let summary) = viewModel.state else {
            Issue.record("Expected .loaded, got \(viewModel.state)")
            return
        }
        #expect(summary.headline == "Arsenal beat ten-man Chelsea")
        #expect(summary.playerOfTheMatch == "Rice")
    }
    
    @Test(arguments: [
        #"{"headline": "H", "bullets": ["a", "b", "c"], "keyStat": "K", "playerOfTheMatch": "Messi"}"#,
        #"{"headline": "H", "bullets": ["a", "b", "c", "d", "e"], "keyStat": "K", "playerOfTheMatch": "Rice"}"#,
    ])
    func validJSONWithInvalidContentFails(json: String) async {
        let client = MockLLMClient(behavior: .respond(json), delay: .zero)
        let viewModel = MatchSummaryViewModel(match: .sample, client: client)

        await viewModel.generate()

        #expect(viewModel.state.isFailed)
    }
    
    @Test
    func networkErrorShowsFailedState() async {
        let client = MockLLMClient(behavior: .fail(.invalidResponse), delay: .zero)
        let viewModel = MatchSummaryViewModel(match: .sample, client: client)

        await viewModel.generate()

        guard case .failed(let message) = viewModel.state else {
            Issue.record("Expected .failed, got \(viewModel.state)")
            return
        }
        #expect(message == LLMError.invalidResponse.localizedDescription)
    }
    
    @Test
    func brokenJSONShouldRespondFailed() async {
        let client = MockLLMClient(behavior: .respond("Sure! here it is"), delay: .zero)
        let viewModel = MatchSummaryViewModel(match: .sample, client: client)

        await viewModel.generate()
        
        guard case .failed(let error) = viewModel.state else {
            Issue.record("Expected .loaded, got \(viewModel.state)")
            return
        }
        #expect(error == SummaryError.invalidJSON.localizedDescription)
    }
}

extension MatchSummaryViewModel.State {
    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }
}
