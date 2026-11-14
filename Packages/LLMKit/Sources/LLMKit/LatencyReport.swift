//
//  LatencyReport.swift
//  LLMKit
//

import Foundation

/// How long one AI request took, as seen by the user.
public struct LatencyReport: Sendable, Equatable, CustomStringConvertible {
    public enum Kind: Sendable, Equatable {
        case complete   // one complete answer (summary, search)
        case stream     // text arriving in pieces (chat)
    }

    public enum Outcome: Sendable, Equatable {
        case succeeded
        case failed
        case cancelled  // the user tapped Stop
    }

    public let kind: Kind
    /// What was asked, e.g. "match_summary v3" or "stream".
    public let label: String
    /// Streams only: time until the first piece of text arrived.
    public let timeToFirstToken: Duration?
    /// Time until the answer was complete (or failed).
    public let total: Duration
    /// Length of the answer received.
    public let characters: Int
    public let outcome: Outcome

    public init(
        kind: Kind,
        label: String,
        timeToFirstToken: Duration? = nil,
        total: Duration,
        characters: Int,
        outcome: Outcome
    ) {
        self.kind = kind
        self.label = label
        self.timeToFirstToken = timeToFirstToken
        self.total = total
        self.characters = characters
        self.outcome = outcome
    }

    /// e.g. "⏱️ stream · first token 0.41 s · total 2.10 s · 486 chars"
    public var description: String {
        var parts = ["⏱️ \(label)"]
        if let timeToFirstToken {
            parts.append("first token \(Self.format(timeToFirstToken))")
        }
        parts.append("total \(Self.format(total))")
        parts.append("\(characters) chars")
        switch outcome {
        case .succeeded: break
        case .failed: parts.append("failed")
        case .cancelled: parts.append("cancelled")
        }
        return parts.joined(separator: " · ")
    }

    /// 1.8423 seconds → "1.84 s"
    static func format(_ duration: Duration) -> String {
        let seconds = Double(duration.components.seconds)
            + Double(duration.components.attoseconds) / 1e18
        return String(format: "%.2f s", seconds)
    }
}
