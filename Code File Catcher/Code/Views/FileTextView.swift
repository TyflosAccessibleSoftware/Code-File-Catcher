import SwiftUI

struct FileTextView: View {
    @ObservedObject var viewModel: FileListViewModel
    
    var body: some View {
        TextEditor(text: $viewModel.aggregatedText)
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
            .textEditorStyle(.plain)
            .scrollContentBackground(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 4)
            .overlay {
                if viewModel.aggregatedText.isEmpty {
                    ContentUnavailableView("No content",
                                           systemImage: "doc.text",
                                           description: Text("Press “Get content” to collect files."))
                    .accessibilityHidden(false)
                }
            }
    }
}

#Preview {
    FileTextView(viewModel: FileListViewModel())
}
