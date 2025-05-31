import UniformTypeIdentifiers
import SwiftUI
import Foundation
import AppKit

final class FileListViewModel: ObservableObject {
    @Published var selectedFolder: URL?
    @Published var availableExtensions: [String] = [
        ".swift", ".plist", ".entitlements",
        ".h", ".c", ".m", ".cpp", ".hpp",
        ".htm", ".css", ".js",
        ".java", ".kt",
        ".json", ".txt", ".md"
    ]
    @Published var selectedExtensions: Set<String> = []
    @Published var files: [FileInfo] = []
    @Published var aggregatedText: String = ""
    @Published var isSearching: Bool = false
    
    func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.title = "Selecciona una carpeta"
        
        if panel.runModal() == .OK {
            selectedFolder = panel.urls.first
            files.removeAll()
            aggregatedText = ""
        }
    }
    
    func searchFiles() {
        guard let folder = selectedFolder else { return }
        let selectedExtensionsCopy = selectedExtensions
        DispatchQueue.main.async {
            self.isSearching = true
            self.files = []
            self.aggregatedText = ""
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let fm = FileManager.default
            var fileURLs: [URL] = []
            if let enumerator = fm.enumerator(at: folder, includingPropertiesForKeys: nil) {
                for case let url as URL in enumerator {
                    let ext = url.pathExtension.lowercased().withDotPrefix
                    guard selectedExtensionsCopy.contains(ext) else { continue }
                    fileURLs.append(url)
                }
            }
            let fileInfos = fileURLs.map { FileInfo(url: $0) }
            DispatchQueue.main.async {
                self.files = fileInfos
            }
            DispatchQueue.global(qos: .utility).async {
                for file in fileInfos {
                    let content = (try? String(contentsOf: file.url, encoding: .utf8)) ?? ""
                    var codeFile = file
                    codeFile.content = content
                    DispatchQueue.main.async {
                        self.files.append(codeFile)
                        self.aggregatedText += "✏️ [\(codeFile.fileName)]\n\n\(codeFile.content)\n\n"
                    }
                    Thread.sleep(forTimeInterval: 0.01)
                }
                DispatchQueue.main.async {
                    self.isSearching = false
                }
            }
        }
    }
    
    private func aggregateFiles() {
        var text = ""
        for file in files {
            text += "✏️ [\(file.fileName)]\n\n"
            text += file.content + "\n\n"
        }
        aggregatedText = text
    }
    
    
    func copyToClipboard() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(aggregatedText, forType: .string)
    }
    
    func exportToTxt() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "allSourceCode.txt"
        savePanel.title = String(localized: "Save as…")
        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? aggregatedText.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

