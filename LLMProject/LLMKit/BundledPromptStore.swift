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
    
    func template(for id: String) async throws -> PromptTemplate {
        guard let url = bundle.url(forResource: id, withExtension: "md") else {
            throw PromptError.fileNotFound(id)
        }
        let contents = try String(contentsOf: url, encoding: .utf8)
        
        let template = try PromptTemplate.parse(contents)
        
        guard template.id == id else {
            throw PromptError.idMismatch(expected: id, found: template.id)
        }
        
        return template
    }
}
