//
//  EventsList.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 11/11/2026.
//

import SwiftUI

struct EventsList: View {
    let match: Match

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Events")
                .font(.headline)

            ForEach(Array(match.events.enumerated()), id: \.offset) { _, event in
                HStack {
                    Text("\(event.minute)'")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 36, alignment: .leading)
                    Text(icon(for: event.type))
                    Text(event.player)
                    Spacer()
                    Text(event.side == .home ? match.homeTeam : match.awayTeam)
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }
        }
    }

    private func icon(for type: Match.EventType) -> String {
        switch type {
        case .goal, .penaltyGoal: "⚽️"
        case .yellowCard: "🟨"
        case .redCard: "🟥"
        }
    }
}
