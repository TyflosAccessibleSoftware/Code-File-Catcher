import SwiftUI

struct SearchingNotificationView: View {
    var body: some View {
        HStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Text("Searching files…")
                .font(.callout)
        }
        .padding()
    }
}

#Preview {
    SearchingNotificationView()
}
