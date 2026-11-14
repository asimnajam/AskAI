//
//  RetryPolicy.swift
//  LLMKit
//

import Foundation

/// When and how long to wait before asking the same model again.
///
/// Retrying the same model is worth it when the problem is temporary
/// (rate limit, overloaded server). The waits grow each time ("exponential backoff")
/// and include some randomness ("jitter"), so many clients don't all retry at once.
public struct RetryPolicy: Sendable, Equatable {
    /// Extra attempts per model after the first one.
    public var maxRetries: Int
    /// Wait before the first retry. Each next retry waits twice as long.
    public var baseDelay: Duration
    /// Never wait longer than this. A server asking for more is skipped instead.
    public var maxDelay: Duration

    public init(maxRetries: Int, baseDelay: Duration, maxDelay: Duration) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
    }

    /// About 0.5 s, then about 1 s, before moving to the next model.
    public static let `default` = RetryPolicy(maxRetries: 2, baseDelay: .milliseconds(500), maxDelay: .seconds(4))

    /// Never retry the same model (go straight to the next one).
    public static let none = RetryPolicy(maxRetries: 0, baseDelay: .zero, maxDelay: .zero)

    /// Statuses where waiting can help: rate limited, or a temporary server problem.
    /// Not 404 (model gone), 400/401 (our request is wrong), or timeouts (we already waited).
    public static func isRetryable(status: Int) -> Bool {
        [429, 500, 502, 503, 504].contains(status)
    }

    /// How long to wait before retry number `retry` (1, 2, …), or nil to stop retrying this model.
    /// - Parameters:
    ///   - retryAfter: what the server asked for (the Retry-After header), if anything.
    ///   - jitter: a random factor between 0.5 and 1.0; passed in so tests can fix it.
    public func delay(
        forRetry retry: Int,
        retryAfter: Duration? = nil,
        jitter: Double = .random(in: 0.5...1.0)
    ) -> Duration? {
        guard retry >= 1, retry <= maxRetries else { return nil }

        // The server knows best, unless it asks for longer than we're willing to wait.
        if let retryAfter {
            return retryAfter <= maxDelay ? retryAfter : nil
        }

        // 0.5 s, 1 s, 2 s, … (capped), then scaled by the random jitter.
        let exponential = baseDelay * (1 << (retry - 1))
        let capped = min(exponential, maxDelay)
        return capped * jitter
    }

    /// Reads a Retry-After header given in seconds, e.g. "2". (The HTTP-date form is ignored.)
    static func retryAfter(from response: HTTPURLResponse) -> Duration? {
        guard let value = response.value(forHTTPHeaderField: "Retry-After"),
              let seconds = Double(value.trimmingCharacters(in: .whitespaces)),
              seconds >= 0 else {
            return nil
        }
        return .milliseconds(Int(seconds * 1000))
    }
}
