import SwiftUI

struct FileTextView: View {
    @ObservedObject var viewModel: FileListViewModel
    var body: some View {
        ScrollView {
            Text(viewModel.aggregatedText)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    FileTextView(viewModel: FileListViewModel())
}
