//
//  SummaryErrorMessageTests.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 11/11/2026.
//


import Testing
import LLMKit
import Foundation
@testable import LLMProject

struct SummaryErrorMessageTests {
    @Test(arguments: zip(
        [
            URLError(.notConnectedToInternet),
            URLError(.timedOut),
            LLMError.http(status: 429, model: "Gemini"),
            LLMError.http(status: 503, model: "Gemini"),
            LLMError.http(status: 400, model: "Gemini"),
            LLMError.invalidResponse,
            SummaryError.invalidJSON,
            SummaryError.unknownPlayer("Messi"),
            
        ] as [any Error],
        [
            SummaryErrorMessage.offline,
            SummaryErrorMessage.generic,
            SummaryErrorMessage.busy,
            SummaryErrorMessage.busy,
            SummaryErrorMessage.generic,
            SummaryErrorMessage.generic,
            SummaryErrorMessage.unreliable,
            SummaryErrorMessage.unreliable
        ]
    ))
    func mapsErrorToFriendlyMessage(error: any Error, expected: String) async throws {
        #expect(SummaryErrorMessage.message(for: error) == expected)
    }
    
    @Test(arguments: [
        URLError(.notConnectedToInternet),
        LLMError.http(status: 400, model: "gemini"),
        SummaryError.invalidJSON
    ] as [any Error])
    func messageNeverContainsTechnicalDetails(error: any Error) {
        let message = SummaryErrorMessage.message(for: error)
        
        #expect(!message.contains("HTTP"))
        #expect(!message.contains("gemini"))
        #expect(!message.isEmpty)
    }
}
