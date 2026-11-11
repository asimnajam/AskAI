//
//  SummaryErrorMessage.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 11/11/2026.
//

import Foundation
import LLMKit

enum SummaryErrorMessage {
    static let offline = "You're offline. Check your connection and try again."
    static let busy = "The AI service is busy right now. Please try again in a moment."
    static let unreliable = "The AI's answer didn't look right, so we didn't show it. Please try again."
    static let generic = "Couldn't create a summary right now. Please try again."

    static func message(for error: Error) -> String {
        switch error {
        case let urlError as URLError where urlError.code == .notConnectedToInternet:
            return offline
        case LLMError.http(let status, _) where [429, 503].contains(status):
            return busy
        case is SummaryError:
            return unreliable
        default:
            return generic
        }
    }
}
