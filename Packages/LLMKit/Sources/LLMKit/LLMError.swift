//
//  LLMError.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 05/11/2026.
//

import Foundation

public enum LLMError: LocalizedError {
    case http(status: Int, model: String)
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .http(let status, let model):
            "Request to \(model) failed (HTTP \(status))"
        case .invalidResponse:
            "The server sent an unexpected response"
        }
    }
}
