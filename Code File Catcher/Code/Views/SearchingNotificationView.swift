import SwiftUI

struct SearchingNotificationView: View {
    @ObservedObject var viewModel: FileListViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            if viewModel.progressTotal > 0 {
                ProgressView(value: Double(viewModel.progressDone),
                             total: Double(viewModel.progressTotal))
            } else {
                ProgressView()
            }
            VStack(alignment: .leading) {
                Text("Searching files…")
                    .font(.callout)
                if viewModel.progressTotal > 0 {
                    Text("\(viewModel.progressDone) / \(viewModel.progressTotal)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Processed \(viewModel.progressDone) of \(viewModel.progressTotal) files")
                }
            }
            Spacer(minLength: 8)
            Button("Cancel") {
                viewModel.cancelSearch()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding(8)
    }
}

#Preview {
    SearchingNotificationView(viewModel: FileListViewModel())
}
