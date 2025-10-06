import UniformTypeIdentifiers
import SwiftUI
import Foundation
import AppKit

@MainActor
final class FileListViewModel: ObservableObject {
    @AppStorage("lastFolderBookmarkKey") private var lastFolderBookmarkData: Data?
    @Published var selectedFolder: URL?
    @Published var availableExtensions: [String] = [
        ".swift", ".plist", ".entitlements",
        ".h", ".c", ".m", ".cpp", ".hpp",
        ".htm", ".css", ".js",
        ".java", ".kt",
        ".php",
        ".json", ".txt", ".md",
        ".strings", ".xcstrings", ".xml", ".*"
    ]
    @Published var selectedExtensions: Set<String> = []
    @Published var files: [FileInfo] = []
    @Published var aggregatedText: String = ""
    @Published var isSearching: Bool = false
    @Published var progressTotal: Int = 0
    @Published var progressDone: Int = 0
    private var searchTask: Task<Void, Never>?
    private let concurrencyLimit = 4
    private var securityScopeActive = false
    
    init() {
        restoreSecurityScopedFolderIfAvailable()
    }
    
    deinit {
        Task { @MainActor in
            self.stopSecurityScopeIfNeeded()
        }
    }
    
    func selectFolder() {
        playSoundClick()
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.title = "Selecciona una carpeta"
        
        if panel.runModal() == .OK, let folderURL = panel.urls.first {
            stopSecurityScopeIfNeeded()
            do {
                let bookmark = try folderURL.bookmarkData(
                    options: [.withSecurityScope],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                lastFolderBookmarkData = bookmark
                selectedFolder = folderURL
                startSecurityScopeIfNeeded(for: folderURL)
            } catch {
                lastFolderBookmarkData = nil
                selectedFolder = nil
                securityScopeActive = false
                NSSound.beep()
                print("ERROR creando bookmark: \(error)")
            }
            
            files.removeAll()
            aggregatedText = ""
            progressTotal = 0
            progressDone = 0
        }
    }
    
    private func restoreSecurityScopedFolderIfAvailable() {
        guard let data = lastFolderBookmarkData else { return }
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: data,
                options: [.withSecurityScope, .withoutUI],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            if isStale {
                let refreshed = try url.bookmarkData(
                    options: [.withSecurityScope],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                lastFolderBookmarkData = refreshed
            }
            
            selectedFolder = url
            startSecurityScopeIfNeeded(for: url)
        } catch {
            lastFolderBookmarkData = nil
            selectedFolder = nil
            securityScopeActive = false
            print("Error: \(error.localizedDescription)")
        }
    }
    
    private func startSecurityScopeIfNeeded(for url: URL) {
        guard !securityScopeActive else { return }
        if url.startAccessingSecurityScopedResource() {
            securityScopeActive = true
        } else {
            print("No se pudo iniciar el acceso security-scoped para: \(url.path)")
        }
    }
    
    private func stopSecurityScopeIfNeeded() {
        guard securityScopeActive else { return }
        selectedFolder?.stopAccessingSecurityScopedResource()
        securityScopeActive = false
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
                    do {
                        let isReg = try url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile ?? false
                        guard isReg else { continue }
                        let ext = "." + url.pathExtension.lowercased()
                        if includeAll || selected.contains(ext) {
                            urls.append(url)
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
            
            await MainActor.run { self.progressTotal = urls.count }
            var collected: [FileInfo] = []
            collected.reserveCapacity(urls.count)
            var chunks: [String] = []
            chunks.reserveCapacity(urls.count)
            
            func readFile(_ url: URL) -> (FileInfo, String?) {
                autoreleasepool {
                    let content = try? String(contentsOf: url, encoding: .utf8)
                    return (FileInfo(url: url), content)
                }
            }
            await withTaskGroup(of: (FileInfo, String?).self) { group in
                var nextIndex = 0
                let initial = min(self.concurrencyLimit, urls.count)
                for _ in 0..<initial {
                    let url = urls[nextIndex]
                    nextIndex += 1
                    group.addTask { readFile(url) }
                }
                
                var completed = 0
                while let result = await group.next() {
                    if Task.isCancelled { break }
                    let (info, text) = result
                    if let content = text {
                        var infoWithContent = info
                        infoWithContent.content = content
                        collected.append(infoWithContent)
                        chunks.append("✏️ [\(info.fileName)]\n\n\(content)\n\n")
                    }
                    
                    completed += 1
                    await MainActor.run {
                        self.progressDone = completed
                    }
                    
                    if nextIndex < urls.count {
                        let url = urls[nextIndex]
                        nextIndex += 1
                        group.addTask { readFile(url) }
                    }
                }
            }
            collected.sort { $0.fileName.localizedStandardCompare($1.fileName) == .orderedAscending }
            await MainActor.run {
                self.files = collected
                let orderedText = collected.map { info in
                    "✏️ [\(info.fileName)]\n\n\(info.content)\n\n"
                }.joined()
                self.aggregatedText = orderedText.isEmpty ? chunks.joined() : orderedText
                
                self.isSearching = false
                self.progressDone = self.progressTotal
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
