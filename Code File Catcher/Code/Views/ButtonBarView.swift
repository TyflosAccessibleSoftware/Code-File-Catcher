import SwiftUI

struct ButtonBarView: View {
    @ObservedObject var viewModel: FileListViewModel

    var body: some View {
        HStack(spacing: 12) {
            Button(action: { viewModel.searchFiles() }) {
                Text("Get content")
                    .font(.headline)
            }
            .disabled(viewModel.selectedFolder == nil ||
                      viewModel.selectedExtensions.isEmpty ||
                      viewModel.isSearching)

            Button(action: { viewModel.copyToClipboard() }) {
                Text("Copy")
                    .font(.body)
            }
            .disabled(viewModel.aggregatedText.isEmpty || viewModel.isSearching)

            Button(action: { viewModel.exportToTxt() }) {
                Text("Export")
            }
            .disabled(viewModel.aggregatedText.isEmpty || viewModel.isSearching)

            Spacer()

            if viewModel.isSearching {
                Button(role: .destructive, action: { viewModel.cancelSearch() }) {
                    Text("Cancel")
                }
                .help("Stop current search")
            }
        }
    }
}

#Preview {
    ButtonBarView(viewModel: FileListViewModel())
}
