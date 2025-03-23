import SwiftUI
import AppKit
import UniformTypeIdentifiers

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register for drag and drop of files
        let fileTypes: [NSPasteboard.PasteboardType] = [.fileURL]
        NSApp.windows.first?.registerForDraggedTypes(fileTypes)
        NSApp.windows.first?.delegate = self
    }
    
    // Allow files to be accepted via Finder opening
    func application(_ app: NSApplication, open urls: [URL]) {
        processOpenedFiles(urls)
    }
    
    // Also implement the older method for compatibility
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        let url = URL(fileURLWithPath: filename)
        processOpenedFiles([url])
        return true
    }
    
    private func processOpenedFiles(_ urls: [URL]) {
        guard let firstURL = urls.first,
              firstURL.pathExtension.lowercased() == "mov" else {
            return
        }
        
        // Post a notification that can be observed in ContentView
        NotificationCenter.default.post(
            name: NSNotification.Name("ProcessMovFile"),
            object: nil,
            userInfo: ["url": firstURL]
        )
    }
}

@main
struct IVConverterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var outputLocation: URL?
    
    var body: some Scene {
        WindowGroup {
            ContentView(outputLocation: $outputLocation)
                .frame(minWidth: 400, minHeight: 300)
                .onAppear {
                    // Register the app to handle files
                    if let windowScene = NSApplication.shared.windows.first {
                        windowScene.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
        .commands {
            CommandGroup(after: .newItem) {
                Button("Choose Output Location") {
                    let savePanel = NSSavePanel()
                    savePanel.allowedContentTypes = [UTType.mpeg4Movie]
                    savePanel.canCreateDirectories = true
                    savePanel.isExtensionHidden = false
                    savePanel.title = "Set Default Output Location"
                    savePanel.message = "Choose where to save converted videos"
                    savePanel.nameFieldLabel = "File name:"
                    savePanel.nameFieldStringValue = "output.mp4"
                    
                    if savePanel.runModal() == .OK, let url = savePanel.url {
                        outputLocation = url.deletingLastPathComponent()
                    }
                }
                .keyboardShortcut("O", modifiers: [.command, .shift])
            }
        }
    }
}
