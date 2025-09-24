import UniformTypeIdentifiers
import SwiftUI
import Foundation
import AppKit

final class FileListViewModel: ObservableObject {
    @AppStorage("lastFolderPathKey") private var lastFolderPath: String = ""
    @Published var selectedFolder: URL?
    @Published var availableExtensions: [String] = [
        ".swift", ".plist", ".entitlements",
        ".h", ".c", ".m", ".cpp", ".hpp",
        ".htm", ".css", ".js",
        ".java", ".kt",
        ".php",
        ".json", ".txt", ".md",
        ".strings", ".xml", ".*"
    ]
    @Published var selectedExtensions: Set<String> = []
    @Published var files: [FileInfo] = []
    @Published var aggregatedText: String = ""
    @Published var isSearching: Bool = false
    
    init() {
        if let lastUrl = URL(string: lastFolderPath) {
            selectedFolder = lastUrl
        }
    }
    
    func selectFolder() {
        playSoundClick()
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.title = "Selecciona una carpeta"
        
        if panel.runModal() == .OK {
            selectedFolder = panel.urls.first
            files.removeAll()
            aggregatedText = ""
            lastFolderPath = "\(selectedFolder!)"
        }
    }
    
    func searchFiles() {
        guard let folder = selectedFolder else { return }
        self.isSearching = true
        self.files = []
        self.aggregatedText = ""
        DispatchQueue.global(qos: .userInitiated).async {
            let fm = FileManager.default
            var collectedFileInfos: [FileInfo] = []
            var completeAggregatedText = ""
            if let enumerator = fm.enumerator(at: folder, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
                for case let url as URL in enumerator {
                    guard let resourceValues = try? url.resourceValues(forKeys: [.isRegularFileKey]),
                          resourceValues.isRegularFile == true else {
                        continue
                    }
                    let ext = "." + url.pathExtension.lowercased()
                    if ext == ".*" || self.selectedExtensions.contains(ext) {
                        if let content = try? String(contentsOf: url, encoding: .utf8) {
                            var fileInfo = FileInfo(url: url)
                            fileInfo.content = content
                            collectedFileInfos.append(fileInfo)
                            completeAggregatedText += "✏️ [\(fileInfo.fileName)]\n\n\(content)\n\n"
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                self.files = collectedFileInfos
                self.aggregatedText = completeAggregatedText
                self.isSearching = false
                playSoundBell()
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
        playSoundClick()
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(aggregatedText, forType: .string)
    }
    
    func exportToTxt() {
        playSoundClick()
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "allSourceCode.txt"
        savePanel.title = String(localized: "Save as…")
        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? aggregatedText.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

