//
//  MatchListView.swift
//  LLMProject
//

import SwiftUI
import LLMKit

struct MatchListView: View {
    let matches: [Match]
    let client: LLMProviding

    var body: some View {
        List(matches) { match in
            NavigationLink(value: match) {
                MatchRow(match: match)
            }
        }
        .navigationTitle("Matches")
        .navigationDestination(for: Match.self) { match in
            MatchSummaryView(match: match, client: client)
        }
        .overlay {
            if matches.isEmpty {
                ContentUnavailableView("No matches", systemImage: "sportscourt")
            }
        }
    }
}

private struct MatchRow: View {
    let match: Match

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(match.competition) · \(match.date)")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(match.homeTeam)
                        .fontWeight(match.homeScore > match.awayScore ? .semibold : .regular)
                    Text(match.awayTeam)
                        .fontWeight(match.awayScore > match.homeScore ? .semibold : .regular)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(verbatim: "\(match.homeScore)")
                    Text(verbatim: "\(match.awayScore)")
                }
                .font(.body.monospacedDigit().weight(.semibold))
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(match.homeTeam) \(match.homeScore), \(match.awayTeam) \(match.awayScore). \(match.competition), \(match.date)")
    }
}

#Preview {
    NavigationStack {
        MatchListView(
            matches: (try? MatchStore().loadMatches()) ?? [.sample],
            client: MockLLMClient(behavior: .respond(MatchSummary.previewJSON))
        )
    }
}
