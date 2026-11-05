//
//  BundledPromptStore.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 05/11/2026.
//

import Foundation

struct BundledPromptStore: PromptStore {
    private let bundle: Bundle
    
    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }
    
    func template(for id: PromptID) async throws -> PromptTemplate {
        guard let url = bundle.url(forResource: id.rawValue, withExtension: "md") else {
            throw PromptError.fileNotFound(id.rawValue)
        }
        let contents = try String(contentsOf: url, encoding: .utf8)
        
        let template = try PromptTemplate.parse(contents)
        
        guard template.id == id.rawValue else {
            throw PromptError.idMismatch(expected: id.rawValue, found: template.id)
        }
        
        return template
    }
}
