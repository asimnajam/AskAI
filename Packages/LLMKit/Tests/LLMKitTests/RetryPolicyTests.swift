//
//  RetryPolicyTests.swift
//  LLMKitTests
//

import Testing
import Foundation
@testable import LLMKit

struct RetryPolicyTests {

    private let policy = RetryPolicy.default   // 2 retries, 0.5 s base, 4 s max

    // MARK: Which errors are retried

    @Test(arguments: [429, 500, 502, 503, 504])
    func temporaryErrorsAreRetryable(status: Int) {
        #expect(RetryPolicy.isRetryable(status: status))
    }

    @Test(arguments: [400, 401, 403, 404])
    func permanentErrorsAreNotRetryable(status: Int) {
        // 404: the model is gone. 400/401/403: our request or key is wrong. Waiting won't help.
        #expect(!RetryPolicy.isRetryable(status: status))
    }

    // MARK: Backoff

    @Test func delaysDoubleWithEachRetry() {
        // jitter 1.0 = no randomness, so the exact values are predictable
        #expect(policy.delay(forRetry: 1, jitter: 1.0) == .milliseconds(500))
        #expect(policy.delay(forRetry: 2, jitter: 1.0) == .seconds(1))
    }

    @Test func jitterShortensTheWait() {
        #expect(policy.delay(forRetry: 2, jitter: 0.5) == .milliseconds(500))
    }

    @Test func delaysAreCappedAtMaxDelay() {
        let many = RetryPolicy(maxRetries: 10, baseDelay: .milliseconds(500), maxDelay: .seconds(4))
        // 0.5 s · 2^9 would be 256 s
        #expect(many.delay(forRetry: 10, jitter: 1.0) == .seconds(4))
    }

    @Test func noDelayAfterTheLastRetry() {
        #expect(policy.delay(forRetry: 3, jitter: 1.0) == nil)   // only 2 retries allowed
        #expect(policy.delay(forRetry: 0, jitter: 1.0) == nil)   // retries start at 1
    }

    @Test func noneNeverRetries() {
        #expect(RetryPolicy.none.delay(forRetry: 1, jitter: 1.0) == nil)
    }

    // MARK: Retry-After

    @Test func serverRetryAfterIsUsedWhenShortEnough() {
        #expect(policy.delay(forRetry: 1, retryAfter: .seconds(2), jitter: 1.0) == .seconds(2))
    }

    @Test func longRetryAfterSkipsToTheNextModel() {
        // The server asks for 30 s; we'd rather try another model than wait that long.
        #expect(policy.delay(forRetry: 1, retryAfter: .seconds(30), jitter: 1.0) == nil)
    }

    @Test(arguments: zip(
        ["2", " 1.5 ", "abc", "-1", nil] as [String?],
        [Duration.seconds(2), .milliseconds(1500), nil, nil, nil] as [Duration?]
    ))
    func parsesRetryAfterHeader(header: String?, expected: Duration?) throws {
        let url = try #require(URL(string: "https://example.com"))
        let headers = header.map { ["Retry-After": $0] } ?? [:]
        let response = try #require(
            HTTPURLResponse(url: url, statusCode: 429, httpVersion: nil, headerFields: headers)
        )

        #expect(RetryPolicy.retryAfter(from: response) == expected)
    }
}
