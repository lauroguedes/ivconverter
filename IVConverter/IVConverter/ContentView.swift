import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var isDropping = false
    @State private var isConverting = false
    @State private var inputURL: URL? = nil
    @State private var outputURL: URL? = nil
    @State private var progress: Float = 0.0
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isDropping ? Color.blue : Color.gray,
                        lineWidth: 2
                    )
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(Color(.systemGray6).opacity(0.5))
                
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
            .onDrop(of: [UTType.movie.identifier], isTargeted: $isDropping) { providers, _ in
                guard let provider = providers.first else { return false }
                
                provider.loadItem(forTypeIdentifier: UTType.movie.identifier) { item, error in
                    if let error = error {
                        showAlert(title: "Error", message: error.localizedDescription)
                        return
                    }
                    
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) else {
                        return
                    }
                    
                    if url.pathExtension.lowercased() != "mov" {
                        showAlert(title: "Invalid File", message: "Please select a MOV file")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.inputURL = url
                    }
                }
                return true
            }
            
            HStack(spacing: 20) {
                Button("Choose Output Location") {
                    let savePanel = NSSavePanel()
                    savePanel.allowedContentTypes = [UTType.mpeg4Movie]
                    savePanel.canCreateDirectories = true
                    savePanel.isExtensionHidden = false
                    savePanel.title = "Save MP4 Video"
                    savePanel.message = "Choose a location to save the converted video"
                    savePanel.nameFieldLabel = "File name:"
                    
                    if let inputName = inputURL?.deletingPathExtension().lastPathComponent {
                        savePanel.nameFieldStringValue = "\(inputName).mp4"
                    } else {
                        savePanel.nameFieldStringValue = "converted.mp4"
                    }
                    
                    if savePanel.runModal() == .OK {
                        self.outputURL = savePanel.url
                    }
                }
                .disabled(inputURL == nil)
                
                Button("Convert") {
                    convertVideo()
                }
                .disabled(inputURL == nil || outputURL == nil || isConverting)
            }
            .padding()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
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
        guard let inputURL = inputURL, let outputURL = outputURL else { return }
        
        isConverting = true
        progress = 0.0
        
        FFMpegService.shared.convertMOVToMP4(inputURL: inputURL, outputURL: outputURL) { currentProgress in
            DispatchQueue.main.async {
                self.progress = currentProgress
            }
        } completion: { success, error in
            DispatchQueue.main.async {
                self.isConverting = false
                
                if success {
                    self.showAlert(title: "Success", message: "Video converted successfully!")
                    self.inputURL = nil
                    self.outputURL = nil
                } else if let error = error {
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
