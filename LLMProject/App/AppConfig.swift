//
//  AppConfig.swift
//  LLMProject
//

import Foundation

enum AppConfig {
    /// The Gemini key from Config/Secrets.xcconfig, or nil in demo mode.
    static var geminiKey: String? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
              !key.isEmpty else {
            return nil
        }
        return key
    }

    static var isDemoMode: Bool { geminiKey == nil }
}
