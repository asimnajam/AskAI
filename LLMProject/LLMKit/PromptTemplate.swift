//
//  PromptTemplate.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 05/11/2026.
//

import Foundation

/// A prompt loaded from a Markdown file with front matter:
///
///     ---
///     id: match_summary
///     version: 1
///     ---
///     Prompt text...
struct PromptTemplate: Codable, Sendable {
    let id: String
    let version: Int
    let text: String
    
    func rendered(with values: [String: String]) throws -> String {
        var renderedText = text
        
        for (key, value) in values {
            renderedText = renderedText.replacingOccurrences(of: "{{\(key)}}", with: value)
        }
        
        if let open = renderedText.range(of: "{{"),
           let close = renderedText.range(of: "}}", range: open.upperBound..<renderedText.endIndex) {
            let name = String(renderedText[open.upperBound..<close.lowerBound])
            throw PromptError.missingValue(name)
        }
        
        return renderedText
    }
}

extension PromptTemplate {
    static func parse(_ fileContents: String) throws -> PromptTemplate {
        let lines = fileContents.components(separatedBy: .newlines)
        // 1. The file must start with "---"
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
            throw PromptError.missingFrontMatter
        }
        // 2. Find the closing "---"
        guard let closingIndex = lines.dropFirst().firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "---" }) else {
            throw PromptError.missingFrontMatter
        }
        
        // 3. Read "key: value" lines between the two markers
        var fields: [String: String] = [:]
        
        for line in lines[1..<closingIndex] {
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = line[..<colon].trimmingCharacters(in: .whitespaces)
            let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            fields[key] = value
        }
        
        // 4. Required fields
        guard let id = fields["id"], !id.isEmpty else {
            throw PromptError.missingField("id")
        }
        guard let versionString = fields["version"] else {
            throw PromptError.missingField("version")
        }
        guard let version = Int(versionString) else {
            throw PromptError.invalidVersion(versionString)
        }
        
        // 5. Everything after the closing "---" is the prompt
        let text = lines[(closingIndex + 1)...]
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return PromptTemplate(id: id, version: version, text: text)
    }
}


