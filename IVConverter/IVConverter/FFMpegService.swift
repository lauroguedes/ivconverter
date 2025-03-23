import Foundation

class FFMpegService {
    static let shared = FFMpegService()
    
    private init() {}
    
    /// Converts a MOV file to MP4 using FFmpeg
    /// - Parameters:
    ///   - inputURL: URL of the MOV file
    ///   - outputURL: URL where the MP4 file will be saved
    ///   - progressHandler: Closure that receives progress updates (0.0 - 1.0)
    ///   - completion: Closure called when conversion is complete
    func convertMOVToMP4(
        inputURL: URL,
        outputURL: URL,
        progressHandler: @escaping (Float) -> Void,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        // Create a process to run FFmpeg
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/ffmpeg")
        
        // Set the arguments for ffmpeg
        process.arguments = [
            "-i", inputURL.path,            // Input file
            "-c:v", "h264",                // Video codec
            "-crf", "23",                  // Constant Rate Factor (quality)
            "-preset", "medium",           // Encoding speed/compression trade-off
            "-c:a", "aac",                 // Audio codec
            "-b:a", "128k",                // Audio bitrate
            "-y",                          // Overwrite output file if it exists
            "-progress", "pipe:1",         // Output progress to stdout
            outputURL.path                 // Output file
        ]
        
        // Set up pipes for standard output and error
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Track duration and progress
        var duration: Float = 0
        var currentTime: Float = 0
        
        // Handle output to track progress
        outputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if data.count > 0 {
                if let output = String(data: data, encoding: .utf8) {
                    let lines = output.components(separatedBy: "\r")
                    for line in lines {
                        if line.hasPrefix("duration=") {
                            let durationStr = line.replacingOccurrences(of: "duration=", with: "")
                            duration = Float(durationStr) ?? 0
                        } else if line.hasPrefix("out_time_ms=") {
                            let timeStr = line.replacingOccurrences(of: "out_time_ms=", with: "")
                            if let timeMs = Float(timeStr) {
                                currentTime = timeMs / 1000000 // Convert microseconds to seconds
                                if duration > 0 {
                                    let progress = min(currentTime / duration, 1.0)
                                    progressHandler(progress)
                                }
                            }
                        } else if line.hasPrefix("progress=") {
                            if line.contains("end") {
                                progressHandler(1.0)
                            }
                        }
                    }
                }
            }
        }
        
        // Handle completion
        do {
            try process.run()
            process.waitUntilExit()
            
            // Clean up pipe handlers
            outputPipe.fileHandleForReading.readabilityHandler = nil
            errorPipe.fileHandleForReading.readabilityHandler = nil
            
            if process.terminationStatus == 0 {
                completion(true, nil)
            } else {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                completion(false, NSError(domain: "FFMpegService", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: errorMessage]))
            }
        } catch {
            completion(false, error)
        }
    }
}
