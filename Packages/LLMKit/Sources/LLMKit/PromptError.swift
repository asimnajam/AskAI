//
//  PromptError.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 05/11/2026.
//

import Foundation

public enum PromptError: LocalizedError, Equatable {
    case missingFrontMatter
    case missingField(String)
    case invalidVersion(String)
    case missingValue(String)
    case fileNotFound(String)
    case idMismatch(expected: String, found: String)
    
    public var errorDescription: String? {
        switch self {
        case .missingFrontMatter:
            "The prompt file must start with a front matter block between '---' lines."
        case .missingField(let name):
            "The prompt file is missing the '\(name)' field."
        case .invalidVersion(let value):
            "The prompt version '\(value)' is not a whole number."
        case .missingValue(let value):
            "Value is missing: \(value)"
        case .fileNotFound(let fileName):
            "File \(fileName) not found in the bundle"
        case .idMismatch(let expected, let found):
            "ID mismatch: expected '\(expected)', found '\(found)'."
        }
    }
}
