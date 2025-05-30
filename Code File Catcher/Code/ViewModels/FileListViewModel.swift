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
        isSearching = true
        files.removeAll()
        aggregatedText = ""
        
        DispatchQueue.global(qos: .userInitiated).async {
            let fm = FileManager.default
            var foundFiles: [FileInfo] = []
            
            if let enumerator = fm.enumerator(at: folder, includingPropertiesForKeys: nil) {
                for case let url as URL in enumerator {
                    guard self.selectedExtensions.contains(url.pathExtension.lowercased().withDotPrefix) else { continue }
                    foundFiles.append(FileInfo(url: url))
                }
            }
            
            var text = ""
            for file in foundFiles {
                text += "✏️ [\(file.fileName)]\n\n"
                text += file.content + "\n\n"
            }
            
            DispatchQueue.main.async {
                self.files = foundFiles
                self.aggregatedText = text
                self.isSearching = false
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
        savePanel.allowedFileTypes = ["txt"]
        savePanel.nameFieldStringValue = "files_aggregated.txt"
        savePanel.title = "Guardar como..."
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? aggregatedText.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

