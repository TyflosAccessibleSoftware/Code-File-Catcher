import Foundation

struct FileInfo: Identifiable {
    let id = UUID()
    let url: URL
    let fileName: String
    var content: String = ""
    
    init(url: URL) {
        self.url = url
        self.fileName = url.lastPathComponent
    }
}
