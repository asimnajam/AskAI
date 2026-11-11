//
//  BundledPromptStoreTests.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 05/11/2026.
//

import Testing
import Foundation
@testable import LLMProject

/// A class from the test target, used to get the test bundle,
/// which doesn't contain the app's prompt files.
private final class TestBundleToken {}

struct BundledPromptStoreTests {
    @Test(arguments: PromptID.allCases)
    func everyPromptLoadsFromAppBundle(id: PromptID) async throws {
        let store = BundledPromptStore()

        let template = try await store.template(for: id)

        #expect(template.id == id.rawValue)
        #expect(template.version >= 1)
        #expect(!template.text.isEmpty)
    }

    @Test func missingFileThrowsFileNotFound() async {
        let store = BundledPromptStore(bundle: Bundle(for: TestBundleToken.self))

        await #expect(throws: PromptError.fileNotFound("match_summary")) {
            try await store.template(for: .matchSummary)
        }
    }
}
