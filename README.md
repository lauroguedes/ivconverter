# IVConverter

A macOS desktop application for converting MOV videos to MP4 format using native AVFoundation framework.

## Features

- Simple drag-and-drop interface for MOV files
- Uses Apple's AVFoundation for high-quality video conversion
- Real-time progress tracking
- Native macOS UI with SwiftUI

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later (for development)

## Installation

### Building from Source

1. Clone this repository
2. Open the IVConverter.xcodeproj file in Xcode
3. Build and run the application

## Usage

1. Launch IVConverter
2. Drag and drop a MOV file onto the application window
3. The application will automatically start the conversion process
4. The application will show a progress bar during conversion
5. Once complete, a success message will appear with the location of the converted file

## How It Works

IVConverter uses AVFoundation with the following conversion approach:

- Uses native Apple frameworks for video transcoding
- Maintains original video quality while converting to MP4 format
- Leverages hardware acceleration for faster conversions
- Preserves metadata and video attributes where possible

These settings provide efficient and high-quality video conversion directly within macOS.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
