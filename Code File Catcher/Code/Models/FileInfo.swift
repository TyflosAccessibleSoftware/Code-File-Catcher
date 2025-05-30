import Foundation

struct FileInfo: Identifiable {
    let id = UUID()
    let url: URL
    
    var fileName: String { url.lastPathComponent }
    
    var content: String {
        (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }
}
