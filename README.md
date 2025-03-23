# IVConverter

A macOS desktop application for converting MOV videos to MP4 format using FFmpeg.

## Features

- Simple drag-and-drop interface for MOV files
- Uses FFmpeg for high-quality video conversion
- Real-time progress tracking
- Native macOS UI with SwiftUI

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later (for development)
- FFmpeg installed on your system

## Installation

### Installing FFmpeg

Before using IVConverter, you need to have FFmpeg installed on your system. The easiest way to install FFmpeg is using Homebrew:

```bash
brew install ffmpeg
```

Alternatively, you can download the FFmpeg binaries from [FFmpeg's official website](https://ffmpeg.org/download.html).

### Building from Source

1. Clone this repository
2. Open the IVConverter.xcodeproj file in Xcode
3. Build and run the application

## Usage

1. Launch IVConverter
2. Drag and drop a MOV file onto the application window
3. Click "Choose Output Location" to select where to save the converted MP4 file
4. Click "Convert" to start the conversion process
5. The application will show a progress bar during conversion
6. Once complete, a success message will appear

## How It Works

IVConverter uses FFmpeg with the following conversion settings:

- Video codec: H.264
- Constant Rate Factor (CRF): 23 (balanced quality/size)
- Preset: medium (balanced speed/compression)
- Audio codec: AAC
- Audio bitrate: 128k

These settings provide a good balance between quality and file size for most video conversion needs.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [FFmpeg](https://ffmpeg.org/) - The powerful multimedia framework used for video conversion
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) - Apple's UI framework for building the application interface
