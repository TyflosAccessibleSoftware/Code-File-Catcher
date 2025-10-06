import SwiftUI

struct FileTypeSelectorView: View {
    @ObservedObject var viewModel: FileListViewModel
    @AppStorage("fileTypeSelectorExpanded") private var isExpanded: Bool = true
    var body: some View {
        DisclosureGroup("File types:", isExpanded: $isExpanded) {
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
}

#Preview {
    FileTypeSelectorView(viewModel: FileListViewModel())
}
