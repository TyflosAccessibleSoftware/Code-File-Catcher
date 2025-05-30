import SwiftUI

struct ButtonBarView: View {
    @ObservedObject var viewModel: FileListViewModel
    var body: some View {
        HStack {
            Button(action: { viewModel.searchFiles() }) {
                Text("Get content")
                    .font(.headline)
            }
            .disabled(viewModel.selectedFolder == nil || viewModel.selectedExtensions.isEmpty || viewModel.isSearching)
            
            Button(action: { viewModel.copyToClipboard() }) {
                Text("Copy")
                    .font(.body)
            }
            .disabled(viewModel.aggregatedText.isEmpty || viewModel.isSearching)
            
            Button(action: { viewModel.exportToTxt() }) {
                Text("Export")
            }
            .disabled(viewModel.aggregatedText.isEmpty || viewModel.isSearching)
        }
    }
}

#Preview {
    ButtonBarView(viewModel: FileListViewModel())
}
