//
//  MatchSearchTests.swift
//  LLMProjectTests
//
//  Tests for the pieces that prepare an AI search:
//  the vocabulary (allowed names), the prompt builder and the JSON schema.
//

import Testing
import Foundation
import LLMKit
@testable import LLMProject

private let allMatches: [Match] = (try? MatchStore().loadMatches()) ?? []

// MARK: - SearchVocabulary

struct SearchVocabularyTests {

    private let vocabulary = SearchVocabulary(matches: allMatches)

    @Test func hasNoDuplicates() {
        // "Premier League" is used by three matches but must appear once.
        #expect(vocabulary.competitions.filter { $0 == "Premier League" }.count == 1)
        #expect(Set(vocabulary.teams).count == vocabulary.teams.count)
        #expect(Set(vocabulary.competitions).count == vocabulary.competitions.count)
        #expect(Set(vocabulary.players).count == vocabulary.players.count)
    }

    @Test func listsAreSorted() {
        #expect(vocabulary.teams == vocabulary.teams.sorted())
        #expect(vocabulary.competitions == vocabulary.competitions.sorted())
        #expect(vocabulary.players == vocabulary.players.sorted())
    }

    @Test func containsBothHomeAndAwayTeams() {
        #expect(vocabulary.teams.contains("Inter"))       // a home team
        #expect(vocabulary.teams.contains("Juventus"))    // an away team
        #expect(vocabulary.teams.count == 14)             // 7 matches, 14 different clubs
    }

    @Test func emptyMatchesGiveEmptyVocabulary() {
        let empty = SearchVocabulary(matches: [])
        #expect(empty.teams.isEmpty && empty.competitions.isEmpty && empty.players.isEmpty)
    }
}

// MARK: - MatchSearchPromptBuilder

struct MatchSearchPromptBuilderTests {

    @Test func systemPromptContainsRealNamesAndNoPlaceholders() async throws {
        let prompt = try await MatchSearchPromptBuilder()
            .build(query: "Liverpool home games", matches: allMatches)

        #expect(prompt.system.contains("Liverpool"))
        #expect(prompt.system.contains("Bundesliga"))
        #expect(prompt.system.contains("Kane"))
        #expect(!prompt.system.contains("{{"))
    }

    @Test func userMessageIsTheSearch() async throws {
        let prompt = try await MatchSearchPromptBuilder()
            .build(query: "Liverpool home games", matches: allMatches)

        #expect(prompt.user == "Search: Liverpool home games")
    }

    @Test func promptIDAndVersionComeFromTheFile() async throws {
        let prompt = try await MatchSearchPromptBuilder()
            .build(query: "anything", matches: allMatches)

        #expect(prompt.promptID == PromptID.matchSearch.rawValue)
        #expect(prompt.promptVersion >= 1)
    }
}

// MARK: - MatchFilters.schemaJSON

struct MatchFiltersSchemaTests {

    private let vocabulary = SearchVocabulary(matches: allMatches)

    /// The schema as a dictionary, plus its "properties".
    private func parsedSchema() throws -> (schema: [String: Any], properties: [String: [String: Any]]) {
        let json = MatchFilters.schemaJSON(vocabulary: vocabulary)
        let schema = try #require(
            try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any],
            "The schema is not a JSON object"
        )
        let properties = try #require(schema["properties"] as? [String: [String: Any]])
        return (schema, properties)
    }

    @Test func isAValidJSONObject() throws {
        let (schema, _) = try parsedSchema()
        #expect(schema["type"] as? String == "object")
    }

    @Test func hasNoRequiredFields() throws {
        // Every filter is optional: the model includes only what the user asked for.
        let (schema, _) = try parsedSchema()
        #expect(schema["required"] == nil)
    }

    @Test func fieldNamesMatchMatchFiltersProperties() throws {
        // Encode a filter with every field set; its JSON keys are the Swift property names.
        let full = MatchFilters(
            team: "x", competition: "x", venue: .home, result: .win, scorer: "x",
            bothTeamsScored: true, hasRedCard: true, minTotalGoals: 1
        )
        let encoded = try #require(
            try JSONSerialization.jsonObject(with: JSONEncoder().encode(full)) as? [String: Any]
        )
        let swiftKeys = Set(encoded.keys)

        let (_, properties) = try parsedSchema()

        // If these differ, the model writes a key the decoder never reads.
        #expect(Set(properties.keys) == swiftKeys)
    }

    @Test func everyFieldUsesAValidJSONSchemaType() throws {
        let validTypes: Set<String> = ["string", "number", "integer", "boolean", "object", "array", "null"]
        let (_, properties) = try parsedSchema()

        for (name, definition) in properties {
            let type = definition["type"] as? String ?? "missing"
            #expect(validTypes.contains(type), "'\(name)' has invalid type '\(type)'")
        }
    }

    @Test func minTotalGoalsIsANonNegativeInteger() throws {
        let (_, properties) = try parsedSchema()
        let field = try #require(properties["minTotalGoals"])

        #expect(field["type"] as? String == "integer")
        #expect(field["minimum"] as? Int == 0)   // a number, not the string "0"
    }

    @Test func enumsComeFromRealDataAndSwiftEnums() throws {
        let (_, properties) = try parsedSchema()

        #expect(properties["team"]?["enum"] as? [String] == vocabulary.teams)
        #expect(properties["competition"]?["enum"] as? [String] == vocabulary.competitions)
        #expect(properties["scorer"]?["enum"] as? [String] == vocabulary.players)
        #expect(properties["venue"]?["enum"] as? [String] == ["home", "away"])
        #expect(properties["result"]?["enum"] as? [String] == ["win", "draw", "loss"])
    }

    @Test func emptyVocabularyLeavesOutNameFields() throws {
        // "enum": [] is invalid JSON Schema, so name fields must be left out instead.
        let json = MatchFilters.schemaJSON(vocabulary: SearchVocabulary(matches: []))
        let schema = try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any]
        let properties = schema?["properties"] as? [String: Any] ?? [:]

        #expect(properties["team"] == nil)
        #expect(properties["competition"] == nil)
        #expect(properties["scorer"] == nil)
    }
}
