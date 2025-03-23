import SwiftUI
import UniformTypeIdentifiers
import AppKit
import AVFoundation

struct ContentView: View {
    @State private var isDropping = false
    @State private var isConverting = false
    @State private var inputURL: URL? = nil
    @State private var progress: Float = 0.0
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // Binding to the output location from the app
    @Binding var outputLocation: URL?
    
    // For handling dropped files more robustly
    @State private var droppedFileURLs: [URL] = []
    
    init(outputLocation: Binding<URL?>) {
        self._outputLocation = outputLocation
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isDropping ? Color.blue : Color.gray,
                        lineWidth: 2
                    )
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(Color(NSColor.lightGray).opacity(0.5))
                
                if let inputURL = inputURL {
                    VStack {
                        Image(systemName: "film")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        Text(inputURL.lastPathComponent)
                            .fontWeight(.medium)
                        
                        if isConverting {
                            ProgressView(value: progress, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle())
                                .frame(width: 200)
                                .padding(.top, 10)
                            Text("\(Int(progress * 100))%")
                                .font(.caption)
                        }
                    }
                } else {
                    VStack {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 40))
                        Text("Drop MOV file here")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.gray)
                }
            }
            .padding()
            .onDrop(of: ["public.file-url"], isTargeted: $isDropping) { providers, _ in
                // Handle the dropped items
                self.droppedFileURLs = [] // Clear previous drops
                
                guard let itemProvider = providers.first else { return false }
                
                if itemProvider.hasItemConformingToTypeIdentifier("public.file-url") {
                    itemProvider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (urlData, error) in
                        guard error == nil else {
                            DispatchQueue.main.async {
                                self.showAlert(title: "Error", message: error!.localizedDescription)
                            }
                            return
                        }
                        
                        // Try to get the URL from the dropped item
                        var url: URL? = nil
                        
                        if let urlData = urlData as? Data {
                            url = URL(dataRepresentation: urlData, relativeTo: nil)
                        } else if let urlString = urlData as? String {
                            url = URL(string: urlString)
                        } else if let droppedURL = urlData as? URL {
                            url = droppedURL
                        }
                        
                        guard let fileURL = url else { return }
                        
                        // Check if it's a MOV file and process
                        DispatchQueue.main.async {
                            if fileURL.pathExtension.lowercased() == "mov" {
                                self.inputURL = fileURL
                                // Start conversion immediately when file is dropped
                                self.convertVideo()
                            } else {
                                self.showAlert(title: "Invalid File", message: "Please select a MOV file. Got: \(fileURL.pathExtension)")
                            }
                        }
                    }
                    return true
                }
                
                return false
            }
            
            // Spacer to push content up and make the app look cleaner
            Spacer()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            // Register for notifications from AppDelegate
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ProcessMovFile"),
                object: nil,
                queue: .main
            ) { notification in
                if let url = notification.userInfo?["url"] as? URL {
                    self.inputURL = url
                    self.convertVideo()
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            self.alertTitle = title
            self.alertMessage = message
            self.showAlert = true
        }
    }
    
    private func convertVideo() {
        guard let inputURL = inputURL else { return }
        
        // Create a save panel to let the user choose where to save the file
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.mpeg4Movie]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.title = "Save MP4 Video"
        savePanel.message = "Choose a location to save the converted video"
        savePanel.nameFieldLabel = "File name:"
        
        // Suggest a name based on the input file
        let inputName = inputURL.deletingPathExtension().lastPathComponent
        savePanel.nameFieldStringValue = "\(inputName).mp4"
        
        // If we have a default output location set, use it
        if let outputLocation = outputLocation {
            savePanel.directoryURL = outputLocation
        }
        
        if savePanel.runModal() != .OK {
            // User cancelled the save dialog
            return
        }
        
        // Now we can safely use the selected save location
        guard let finalOutputURL = savePanel.url else { return }
        
        isConverting = true
        progress = 0.0
        
        FFMpegService.shared.convertMOVToMP4(inputURL: inputURL, outputURL: finalOutputURL) { currentProgress in
            DispatchQueue.main.async {
                self.progress = currentProgress
            }
        } completion: { success, error in
            DispatchQueue.main.async {
                self.isConverting = false
                
                if success {
                    // Show more info about where the file was saved
                    let savedMessage = "Video converted successfully!\n\nThe file has been saved to:\n\(finalOutputURL.path)\n\nFinder will open to show the file location."
                    self.showAlert(title: "Success", message: savedMessage)
                    self.inputURL = nil
                } else if let error = error {
                    // Show a more user-friendly error message
                    let errorMsg = "Error during conversion: \(error.localizedDescription)\n\nPlease try again or choose a different location for saving."
                    self.showAlert(title: "Conversion Error", message: errorMsg)
                }
            }
        }
    }
}

#Preview {
    ContentView(outputLocation: .constant(nil))
}
