import Foundation
import AVFoundation

// Make this class public so it can be accessed from ContentView
public class AVFoundationConverter {
    public static let shared = AVFoundationConverter()
    
    private init() {}
    
    /// Converts a MOV file to MP4 using AVFoundation
    /// - Parameters:
    ///   - inputURL: URL of the MOV file
    ///   - outputURL: URL where the MP4 file will be saved
    ///   - progressHandler: Closure that receives progress updates (0.0 - 1.0)
    ///   - completion: Closure called when conversion is complete
    public func convertMOVToMP4(
        inputURL: URL,
        outputURL: URL,
        progressHandler: @escaping (Float) -> Void,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        print("=========== STARTING NATIVE CONVERSION ===========")
        print("Input file: \(inputURL.path)")
        print("Output file: \(outputURL.path)")
        
        // Check that input file exists and is readable
        let fileManager = FileManager.default
        
        // Check that input file exists
        if !fileManager.fileExists(atPath: inputURL.path) {
            let error = NSError(domain: "AVFoundationConverter", code: 404, 
                               userInfo: [NSLocalizedDescriptionKey: "Input file not found at \(inputURL.path)"])
            print("Error: Input file not found")
            completion(false, error)
            return
        }
        
        // Make sure output directory exists
        let outputDir = outputURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: outputDir.path) {
            do {
                try fileManager.createDirectory(at: outputDir, withIntermediateDirectories: true)
            } catch {
                completion(false, NSError(domain: "AVFoundationConverter", code: 500, userInfo: [NSLocalizedDescriptionKey: "Cannot create output directory: \(error.localizedDescription)"]))
                return
            }
        }
        
        // Remove output file if it already exists
        if fileManager.fileExists(atPath: outputURL.path) {
            do {
                try fileManager.removeItem(at: outputURL)
            } catch {
                completion(false, NSError(domain: "AVFoundationConverter", code: 500, userInfo: [NSLocalizedDescriptionKey: "Cannot overwrite existing output file: \(error.localizedDescription)"]))
                return
            }
        }
        
        // Create the asset to export
        let asset = AVURLAsset(url: inputURL)
        
        // Create export session
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            completion(false, NSError(domain: "AVFoundationConverter", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not create export session"]))
            return
        }
        
        // Configure export session
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        print("Starting export with AVAssetExportSession")
        
        // Setup progress monitoring with a timer
        let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            let progress = exportSession.progress
            progressHandler(progress)
            
            // Check if export is complete
            if exportSession.progress >= 1.0 || 
               exportSession.status == .completed || 
               exportSession.status == .failed || 
               exportSession.status == .cancelled {
                timer.invalidate()
            }
        }
        
        // Start the export
        exportSession.exportAsynchronously {
            progressTimer.invalidate() // Ensure timer is invalidated
            
            switch exportSession.status {
            case .completed:
                print("Conversion completed successfully")
                progressHandler(1.0)
                completion(true, nil)
                
            case .failed:
                print("Conversion failed with error: \(exportSession.error?.localizedDescription ?? "Unknown error")")
                completion(false, exportSession.error)
                
            case .cancelled:
                print("Conversion was cancelled")
                completion(false, NSError(domain: "AVFoundationConverter", code: 500, userInfo: [NSLocalizedDescriptionKey: "Export was cancelled"]))
                
            default:
                print("Conversion ended with status: \(exportSession.status.rawValue)")
                completion(false, NSError(domain: "AVFoundationConverter", code: 500, userInfo: [NSLocalizedDescriptionKey: "Export ended with unknown status"]))
            }
        }
    }
}