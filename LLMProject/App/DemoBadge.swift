//
//  DemoBadge.swift
//  LLMProject
//

import SwiftUI

extension View {
    /// Shows a "Demo" label in the toolbar when the app has no API key,
    /// so it's clear the answers are sample data, not a real model.
    func demoBadge() -> some View {
        toolbar {
            if AppConfig.isDemoMode {
                ToolbarItem(placement: .primaryAction) {
                    Label("Demo", systemImage: "theatermasks")
                        .labelStyle(.titleAndIcon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                        .accessibilityLabel("Demo mode: answers are sample data")
                }
            }
        }
    }
}
