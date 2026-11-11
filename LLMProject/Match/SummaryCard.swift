//
//  SummaryCard.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 11/11/2026.
//

import SwiftUI

struct SummaryCard: View {
    let summary: MatchSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("AI-generated summary", systemImage: "sparkles")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(summary.headline)
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(summary.bullets.enumerated()), id: \.offset) { _, bullet in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("•")
                        Text(bullet)
                    }
                }
            }

            Divider()

            Label(summary.keyStat, systemImage: "chart.bar.fill")
            Label("Player of the match: \(summary.playerOfTheMatch)", systemImage: "star.fill")
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }
}
