import SwiftUI
import LLMKit

struct ChatView: View {
    @State private var viewModel: ChatViewModel

    init(client: LLMProviding) {
        _viewModel = State(initialValue: ChatViewModel(client: client))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
            .defaultScrollAnchor(.bottom)

            Divider()

            HStack {
                TextField("Ask something…", text: $viewModel.input, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)

                Button(viewModel.primaryActionTitle) {
                    viewModel.primaryActionTapped()
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.isStreaming ? .red : .blue)
            }
            .padding()
        }
    }
}

#Preview("Chat") {
    NavigationStack {
        ChatView(
            client: MockLLMClient(
                behavior: .respond("Offside means an attacker is closer to the opponent's goal line than both the ball and the second-last defender when the ball is played to them.")
            )
        )
        .navigationTitle("Chat")
    }
}

#Preview("Chat error") {
    NavigationStack {
        ChatView(client: MockLLMClient(behavior: .fail(.invalidResponse)))
            .navigationTitle("Chat")
    }
}
