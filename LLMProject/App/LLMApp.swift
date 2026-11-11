import SwiftUI
import LLMKit

@main
struct LLMApp: App {
    private let chatClient: any LLMProviding
    private let summaryClient: any LLMProviding

    init() {
        if let key = AppConfig.geminiKey {
            // A key is configured: both features share the real Gemini client.
            let gemini = LLMClient(
                endpoint: URL(string: "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions")!,
                apiKey: key,
                timeout: 20,
                models: ["gemini-flash-lite-latest", "gemini-3.5-flash", "gemini-3.8-flash"]
            )
            chatClient = gemini
            summaryClient = gemini
        } else {
            // No key (e.g. a fresh clone): demo mode with sample answers per feature.
            print("ℹ️ No GEMINI_API_KEY found, running in demo mode")
            chatClient = MockLLMClient(behavior: .respond(Self.demoChatAnswer))
            summaryClient = MockLLMClient(behavior: .respond(MatchSummary.previewJSON))
        }
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Chat", systemImage: "bubble.left.and.bubble.right") {
                    NavigationStack {
                        ChatView(client: chatClient)
                            .navigationTitle("Chat")
                            .demoBadge()
                    }
                }

                Tab("Match", systemImage: "sportscourt") {
                    NavigationStack {
                        MatchSummaryView(match: .sample, client: summaryClient)
                            .demoBadge()
                    }
                }
            }
        }
    }

    private static let demoChatAnswer = """
    This is demo mode, so this is a sample answer. Add your Gemini key to \
    Config/Secrets.xcconfig to chat with a real model.
    """
}
