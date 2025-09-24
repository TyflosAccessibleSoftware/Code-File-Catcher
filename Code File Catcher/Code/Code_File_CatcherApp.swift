import SwiftUI

@main
struct Code_File_CatcherApp: App {
    
    init() {
        loadSounds()
    }
    
    var body: some Scene {
        WindowGroup {
            FileListView()
        }
    }
}
