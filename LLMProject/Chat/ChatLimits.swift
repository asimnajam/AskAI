//
//  ChatLimits.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 12/11/2026.
//

enum ChatLimits {
    /// Longest message a user can send.
    static let maxInputCharacters = 500
    /// How many recent messages are sent to the model as context.
    static let maxHistoryMessages = 10
}
