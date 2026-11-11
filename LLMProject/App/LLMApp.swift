import SwiftUI

@main struct LLMApp: App {
    let client: LLMClient = .init(
        endpoint: URL(string: "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions")!,
        apiKey: Secrets.geminiKey,
        timeout: 20,
        models: ["gemini-flash-lite-latest", "gemini-3.5-flash", "gemini-3.8-flash"])
    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Chat", systemImage: "bubble.left.and.bubble.right") {
                    NavigationStack {
                        ChatView(client: client)
                            .navigationTitle("Chat")
                    }
                }
                
                Tab("Match", systemImage: "sportscourt") {
                    NavigationStack {
                        MatchSummaryView(match: .sample, client: client)
                    }
                }
            }
        }
//        TabView {
//            <#code#>
//        }
//        WindowGroup {
//            NavigationStack {
//                MatchSummaryView(match: .sample, client: client)
//            }
////            ChatView()
////                .task {
////                    do {
////                        let prompt = try await MatchSummaryPromptBuilder(promptStore: BundledPromptStore())
////                            .build(for: .sample)
////
////                        let response = try await LLMClient().complete(
////                            prompt,
////                            schemaJSON: MatchSummary.schemaJSON(for: .sample),
////                            temperature: 0.2
////                        )
////                        print("📦 \(response.content)")
////
////                        let summary = try MatchSummary.decode(from: response.content)
////                        try summary.validate(against: .sample)
////                        print("✅ Valid summary: \(summary.headline)")
////                    } catch {
////                        print("❌ \(error)")
////                    }
////                }
//        }
    }
}
