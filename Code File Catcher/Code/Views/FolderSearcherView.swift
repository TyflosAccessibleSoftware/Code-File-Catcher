import SwiftUI

struct FolderSearcherView: View {
    @ObservedObject var viewModel: FileListViewModel
    var body: some View {
        HStack {
            if let folder = viewModel.selectedFolder {
                Text(folder.path)
                    .font(.footnote)
                    .lineLimit(1)
                    .truncationMode(.middle)
            } else {
                Text("Select the folder of your project")
                    .font(.footnote)
            }
            Button(action: { viewModel.selectFolder() }) {
                Text("Select folder")
                    .font(.body)
            }
        }
    }
}

#Preview {
    FolderSearcherView(viewModel: FileListViewModel())
}
