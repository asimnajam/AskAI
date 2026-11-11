//
//  MessageBubble.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 11/11/2026.
//

import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    
    init(message: ChatMessage) {
        self.message = message
        if message.role == .assistant {
            print("****> Message: \(message.text)")
        }
    }

    var body: some View {
        Text(rendered)
            .padding(10)
            .background(
                message.role == .user ? Color.blue.opacity(0.15) : Color.gray.opacity(0.15),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }
    
    private var rendered: AttributedString {
        guard !message.text.isEmpty else { return "…" }
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        return (try? AttributedString(markdown: message.text, options: options))
            ?? AttributedString(message.text)
    }
}
