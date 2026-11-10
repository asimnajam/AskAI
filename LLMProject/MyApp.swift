import SwiftUI

@main struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ChatView()
                .task {
                    do {
                        let prompt = try await MatchSummaryPromptBuilder(promptStore: BundledPromptStore())
                            .build(for: .sample)

                        let response = try await LLMClient().complete(
                            prompt,
                            schemaJSON: MatchSummary.schemaJSON(for: .sample),
                            temperature: 0.2
                        )
                        print("📦 \(response.content)")

                        let summary = try MatchSummary.decode(from: response.content)
                        try summary.validate(against: .sample)
                        print("✅ Valid summary: \(summary.headline)")
                    } catch {
                        print("❌ \(error)")
                    }
                }
        }
    }
}
