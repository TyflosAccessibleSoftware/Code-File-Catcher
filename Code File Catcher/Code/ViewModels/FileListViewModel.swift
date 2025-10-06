import UniformTypeIdentifiers
import SwiftUI
import Foundation
import AppKit

@MainActor
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
        ".strings", ".xcstrings", .xml", ".*"
    ]
    @Published var selectedExtensions: Set<String> = []
    
    @Published var files: [FileInfo] = []
    @Published var aggregatedText: String = ""
    
    @Published var isSearching: Bool = false
    @Published var progressTotal: Int = 0
    @Published var progressDone: Int = 0
    
    private var searchTask: Task<Void, Never>?
    
    init() {
        if let url = URL(string: lastFolderPath) {
            selectedFolder = url
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
            lastFolderPath = selectedFolder?.absoluteString ?? ""
        }
    }
    
    func searchFiles() {
        playSoundClick()
        guard !isSearching, let folder = selectedFolder else { return }
        isSearching = true
        progressTotal = 0
        progressDone = 0
        files = []
        aggregatedText = ""
        
        let selected = selectedExtensions
        let includeAll = selected.contains(".*")
        searchTask?.cancel()
        
        searchTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            
            var urls: [URL] = []
            let fm = FileManager.default
            if let enumerator = fm.enumerator(
                at: folder,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) {
                for case let url as URL in enumerator {
                    if Task.isCancelled { return }
                    guard
                        let isReg = try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile,
                        isReg == true
                    else { continue }
                    
                    let ext = "." + url.pathExtension.lowercased()
                    if includeAll || selected.contains(ext) {
                        urls.append(url)
                    }
                }
            }
            
            await MainActor.run { self.progressTotal = urls.count }
            
            var collected: [FileInfo] = []
            var completeAggregatedText = ""
            
            for (idx, url) in urls.enumerated() {
                if Task.isCancelled { break }
                
                autoreleasepool {
                    if let content = try? String(contentsOf: url, encoding: .utf8) {
                        var info = FileInfo(url: url)
                        info.content = content
                        collected.append(info)
                        completeAggregatedText += "✏️ [\(info.fileName)]\n\n\(content)\n\n"
                    }
                }
                
                if idx % 10 == 0 {
                    await MainActor.run { self.progressDone = idx + 1 }
                    await Task.yield()
                }
            }
            
            
            await MainActor.run {
                self.files = collected
                self.aggregatedText = completeAggregatedText
                self.progressDone = self.progressTotal
                self.isSearching = false
                playSoundBell()
            }
        }
    }
    
    func cancelSearch() {
        guard isSearching else { return }
        playSoundClick()
        searchTask?.cancel()
        isSearching = false
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
