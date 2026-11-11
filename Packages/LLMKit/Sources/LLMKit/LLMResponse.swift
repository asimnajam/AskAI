//
//  LLMResponse.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 05/11/2026.
//

public struct LLMResponse: Sendable {
    public let content: String   // the model's answer
    public let model: String     // which model actually answered
}
