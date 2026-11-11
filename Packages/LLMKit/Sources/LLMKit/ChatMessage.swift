//
//  ChatMessage.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 05/11/2026.
//

import Foundation

public struct ChatMessage: Identifiable, Sendable {
    public let id = UUID()
    public let role: Role
    public var text: String
    
    public init(role: Role, text: String) {
        self.role = role
        self.text = text
    }
}
