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

#Preview("Summary") {
    NavigationStack {
        MatchSummaryView(
            match: .sample,
            client: MockLLMClient(behavior: .respond(MatchSummary.previewJSON))
        )
    }
}

#Preview("Error") {
    NavigationStack {
        MatchSummaryView(
            match: .sample,
            client: MockLLMClient(behavior: .fail(.invalidResponse))
        )
    }
}

#Preview("Slow") {
    NavigationStack {
        MatchSummaryView(
            match: .sample,
            client: MockLLMClient(
                behavior: .respond(MatchSummary.previewJSON),
                delay: .seconds(5)
            )
        )
    }
}
