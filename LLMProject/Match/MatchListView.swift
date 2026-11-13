//
//  MatchListView.swift
//  LLMProject
//

import SwiftUI
import LLMKit

struct MatchListView: View {
    private let client: LLMProviding
    @State private var search: MatchSearchViewModel

    init(matches: [Match], client: LLMProviding) {
        self.client = client
        _search = State(initialValue: MatchSearchViewModel(matches: matches, client: client))
    }

    var body: some View {
        List {
            searchStatus

            ForEach(search.results) { match in
                NavigationLink(value: match) {
                    MatchRow(match: match)
                }
            }
        }
        .navigationTitle("Matches")
        .navigationDestination(for: Match.self) { match in
            MatchSummaryView(match: match, client: client)
        }
        .searchable(text: $search.query, prompt: "Try \"Liverpool home defeats\"")
        // Search when the user presses Search, not on every keystroke:
        // each AI call costs time and quota, and half-typed words make bad searches.
        .onSubmit(of: .search) {
            Task { await search.search() }
        }
        .onChange(of: search.query) { _, newValue in
            if newValue.isEmpty { search.clear() }   // ✕ or Cancel in the search field
        }
        .overlay {
            if search.results.isEmpty && !search.isSearching {
                if search.query.isEmpty {
                    ContentUnavailableView("No matches", systemImage: "sportscourt")
                } else {
                    ContentUnavailableView.search(text: search.query)
                }
            }
        }
    }

    /// What the app understood: a loading row, the AI's filter chips, or a keyword note.
    @ViewBuilder
    private var searchStatus: some View {
        if search.isSearching {
            Section {
                Label {
                    Text("Understanding your search…")
                } icon: {
                    ProgressView()
                }
                .foregroundStyle(.secondary)
            }
        } else {
            switch search.mode {
            case .none:
                EmptyView()
            case .ai(let filters):
                Section {
                    FilterChipsView(chips: filters.chips) { field in
                        search.remove(field)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                } header: {
                    Label("AI filters", systemImage: "sparkles")
                }
            case .keyword:
                Section {
                    Label("Showing text matches", systemImage: "text.magnifyingglass")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

/// A horizontal row of removable chips.
private struct FilterChipsView: View {
    let chips: [MatchFilters.Chip]
    let onRemove: (MatchFilters.Field) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chips) { chip in
                    Button {
                        onRemove(chip.field)
                    } label: {
                        HStack(spacing: 4) {
                            Text(chip.label)
                            Image(systemName: "xmark")
                                .font(.caption2.weight(.bold))
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.tint.opacity(0.15), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(chip.label). Remove filter")
                }
            }
            .padding(.horizontal)
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

#Preview("Matches") {
    NavigationStack {
        MatchListView(
            matches: (try? MatchStore().loadMatches()) ?? [.sample],
            client: MockLLMClient(behavior: .respond(MatchSummary.previewJSON))
        )
    }
}

#Preview("AI search") {
    // Type anything and press Search: the mock "understands" it as City away wins.
    NavigationStack {
        MatchListView(
            matches: (try? MatchStore().loadMatches()) ?? [.sample],
            client: MockLLMClient(
                behavior: .respond(#"{"team": "Manchester City", "venue": "away", "result": "win"}"#)
            )
        )
    }
}
