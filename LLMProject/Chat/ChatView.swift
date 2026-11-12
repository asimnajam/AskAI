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

            VStack(alignment: .trailing, spacing: 4) {
                HStack(alignment: .bottom) {
                    TextField("Ask something…", text: $viewModel.input, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)

                    Button(viewModel.primaryActionTitle) {
                        viewModel.primaryActionTapped()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(viewModel.isStreaming ? .red : .blue)
                    // Stop must always work; Send only when the message is valid.
                    .disabled(!viewModel.isStreaming && !viewModel.canSend)
                }

                if viewModel.remainingCharacters <= 50 {
                    // verbatim: show the plain number, without locale formatting like "-1.657"
                    Text(verbatim: "\(viewModel.remainingCharacters)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(viewModel.remainingCharacters < 0 ? .red : .secondary)
                        .padding(.trailing, 4)
                        .accessibilityLabel(
                            viewModel.remainingCharacters < 0
                                ? "\(-viewModel.remainingCharacters) characters over the limit"
                                : "\(viewModel.remainingCharacters) characters left"
                        )
                }
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
