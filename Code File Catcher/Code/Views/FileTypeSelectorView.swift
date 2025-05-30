import SwiftUI

struct FileTypeSelectorView: View {
    @ObservedObject var viewModel: FileListViewModel
    var body: some View {
        Text("File types:")
            .font(.headline)
            .accessibilityAddTraits(.isHeader)
        WrapView(items: viewModel.availableExtensions, id: \.self) { ext in
            Button(action: {
                if viewModel.selectedExtensions.contains(ext) {
                    viewModel.selectedExtensions.remove(ext)
                } else {
                    viewModel.selectedExtensions.insert(ext)
                }
            }) {
                Text(ext)
                    .padding(6)
                    .background(viewModel.selectedExtensions.contains(ext) ? Color.accentColor.opacity(0.3) : Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
            .accessibilityAddTraits(viewModel.selectedExtensions.contains(ext) ? [.isButton, .isSelected] : .isButton)
        }
    }
}

#Preview {
    FileTypeSelectorView(viewModel: FileListViewModel())
}
