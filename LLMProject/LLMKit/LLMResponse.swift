//
//  LLMResponse.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 05/11/2026.
//

struct LLMResponse: Sendable {
    let content: String   // the model's answer
    let model: String     // which model actually answered
}
