//
//  LLMPrompt.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 05/11/2026.
//

public struct LLMPrompt: Sendable {
    public let system: String
    public let user: String
    public let promptID: String
    public let promptVersion: Int
    
    public init(system: String, user: String, promptID: String, promptVersion: Int) {
        self.system = system
        self.user = user
        self.promptID = promptID
        self.promptVersion = promptVersion
    }
}
