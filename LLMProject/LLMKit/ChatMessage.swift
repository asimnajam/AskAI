//
//  ChatMessage.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 05/11/2026.
//

import Foundation

struct ChatMessage: Identifiable, Sendable {
    let id = UUID()
    let role: Role
    var text: String
}
