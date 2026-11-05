import SwiftUI
import Playgrounds

struct ChatView: View {
    @State private var vm = ChatViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(vm.messages) { message in
                        
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
            .defaultScrollAnchor(.bottom)

            Divider()

            HStack {
                TextField("Ask something…", text: $vm.input, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .onSubmit { vm.send() }

                Button(vm.isStreaming ? "Stop" : "Send") {
                    vm.isStreaming ? vm.stop() : vm.send()
                }
                .buttonStyle(.borderedProminent)
                .tint(vm.isStreaming ? .red : .blue)
            }
            .padding()
        }
    }
}

private struct MessageBubble: View {
    let message: ChatMessage
    
    init(message: ChatMessage) {
        self.message = message
        if message.role == .assistant {
            print("****> Message: \(message.text)")
        }
    }

    var body: some View {
        Text(rendered)
            .padding(10)
            .background(
                message.role == .user ? Color.blue.opacity(0.15) : Color.gray.opacity(0.15),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }
    
    private var rendered: AttributedString {
        guard !message.text.isEmpty else { return "…" }
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        return (try? AttributedString(markdown: message.text, options: options))
            ?? AttributedString(message.text)
    }
}

#Preview {
    ChatView()
}
