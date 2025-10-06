import SwiftUI

struct FileListView: View {
    @StateObject private var viewModel = FileListViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            FolderSearcherView(viewModel: viewModel)
            FileTypeSelectorView(viewModel: viewModel)
            ButtonBarView(viewModel: viewModel)

            if viewModel.isSearching {
                SearchingNotificationView(viewModel: viewModel)
            } else {
                FileTextView(viewModel: viewModel)
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
    }
}

#Preview {
    FileListView()
}
