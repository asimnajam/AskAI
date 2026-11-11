//
//  MatchSummaryView.swift
//  LLMProject
//
//  Created by Syed Asim Najam on 10/11/2026.
//

import SwiftUI
import LLMKit

struct MatchSummaryView: View {
    @State private var viewModel: MatchSummaryViewModel

    init(match: Match, client: LLMProviding) {
        _viewModel = State(initialValue: MatchSummaryViewModel(match: match, client: client))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                MatchHeader(match: viewModel.match)
                summarySection
                EventsList(match: viewModel.match)
            }
            .padding()
        }
        .navigationTitle("Match")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Summary states

    @ViewBuilder
    private var summarySection: some View {
        switch viewModel.state {
        case .idle:
            Button {
                Task { await viewModel.generate() }
            } label: {
                Label("AI summary", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

        case .loading:
            HStack(spacing: 12) {
                ProgressView()
                Text("Summarizing the match…")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))

        case .loaded(let summary):
            SummaryCard(summary: summary)

        case .failed(let message):
            VStack(alignment: .leading, spacing: 8) {
                Label("Couldn't create a summary", systemImage: "exclamationmark.triangle")
                    .font(.headline)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Try again") {
                    Task { await viewModel.generate() }
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Header

private struct MatchHeader: View {
    let match: Match

    var body: some View {
        VStack(spacing: 8) {
            Text("\(match.competition) · \(match.date)")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Text(match.homeTeam)
                    .frame(maxWidth: .infinity)
                Text("\(match.homeScore) – \(match.awayScore)")
                    .font(.largeTitle.bold())
                    .monospacedDigit()
                Text(match.awayTeam)
                    .frame(maxWidth: .infinity)
            }
            .font(.title3.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Summary card

private struct SummaryCard: View {
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

// MARK: - Events

private struct EventsList: View {
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
