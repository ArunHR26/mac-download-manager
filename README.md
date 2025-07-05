# Mac Download Manager

A fast, intelligent command-line downloader for macOS with parallel downloads, resume capability, and automatic file type detection.

## Features

- 🚀 **Parallel Downloads**: Auto-detects optimal number of connections for maximum speed
- 🔄 **Resume Support**: Automatically resumes interrupted downloads
- 📊 **Progress Tracking**: Real-time progress with speed and ETA
- 🎯 **Smart File Detection**: Automatically detects and fixes file extensions
- 🛡️ **Duplicate Protection**: Prevents overwriting existing files
- ⚡ **Speed Testing**: Quick connection speed test before download

## Installation

### Option 1: Direct Download (Easiest for Testing)
```bash
# Download the binary
curl -L -o mac-download-manager https://github.com/ArunHR26/mac-download-manager/releases/download/v1.0.0/MacDownloadManager

# Make it executable
chmod +x mac-download-manager

# Move to your PATH (optional)
sudo mv mac-download-manager /usr/local/bin/
```

### Option 2: Build from Source
```bash
# Clone the repository
git clone https://github.com/ArunHR26/mac-download-manager.git
cd mac-download-manager

# Build the project
swift build -c release

# Test the binary
.build/release/MacDownloadManager
```

### Option 3: Homebrew (After Tap Setup)
```bash
brew install ArunHR26/mac-download-manager/mac-download-manager
```

## Usage

### Basic Usage
```bash
mac-download-manager <URL> [output_file] [connections]
```

### Examples
```bash
# Download with auto-detected optimal connections
mac-download-manager https://example.com/file.zip

# Download with custom filename
mac-download-manager https://example.com/file.zip myfile.zip

# Download with specific number of connections
mac-download-manager https://example.com/file.zip myfile.zip 4

# Download with auto filename and custom connections
mac-download-manager https://example.com/file.zip 3
```

### Features
- **Auto filename**: Uses original filename from URL if not specified
- **Auto connections**: Tests 1-4 connections and picks the fastest
- **Progress display**: Shows percentage, speed, and ETA
- **File type detection**: Automatically fixes file extensions
- **Resume support**: Automatically resumes interrupted downloads
- **Cancel with Ctrl+C**: Safely cancel downloads

## Testing

### Quick Test
```bash
# Test help message
mac-download-manager

# Test with a small file
mac-download-manager "https://httpbin.org/bytes/1024" test-file.bin
```

### Parallel Download Test
```bash
# Test with a larger file to see parallel connections
mac-download-manager "https://files.testfile.org/Video%20MP4%2FRecord%20-%20testfile.org.mp4" test-video.mp4
```

### Resume Functionality Test
```bash
# Start a download
mac-download-manager "https://files.testfile.org/Video%20MP4%2FRecord%20-%20testfile.org.mp4" resume-test.mp4

# Interrupt with Ctrl+C after a few seconds
# Then run the same command again - it should resume
```

### Custom Connections Test
```bash
# Test with 1 connection
mac-download-manager "https://files.testfile.org/Video%20MP4%2FRecord%20-%20testfile.org.mp4" test-1.mp4 1

# Test with 4 connections
mac-download-manager "https://files.testfile.org/Video%20MP4%2FRecord%20-%20testfile.org.mp4" test-4.mp4 4
```

### File Type Detection Test
```bash
# Test with different file types
mac-download-manager "https://files.testfile.org/PDF%2FTest%20PDF%20file.pdf"
mac-download-manager "https://files.testfile.org/Image%20JPG%2FTest%20JPG%20file.jpg"
```

### Expected Output
```
🚀 Starting smart download...
URL: https://example.com/file.mp4
Output: file.mp4
📁 File size: 34.7 MB
🔍 Quick connection speed test...
📊 Connection test results:
  3 connection(s): 12.6 MB/s
  2 connection(s): 10.3 MB/s
  1 connection(s): 10.3 MB/s
  4 connection(s): 7.2 MB/s
✅ Optimal connections: 3
📥 Starting download with 3 connection(s)...
⏳ Initializing download...
🚀 Download started!
📊 Progress: 45.2% | 15.7 MB/34.7 MB | Speed: 8.3 MB/s | ETA: 00:02
🔧 Merging chunks...
📝 Detected file type: MP4
✅ Download completed: /path/to/file.mp4
```

## Supported File Types

The downloader automatically detects and fixes extensions for:
- **Video**: MP4, MKV, AVI, MOV, WebM
- **Audio**: MP3, FLAC, OGG, WAV, M4A, WMA, AAC
- **Images**: PNG, JPG, GIF, BMP, TIFF, ICO, WebP, HEIC
- **Documents**: PDF, DOC, DOCX, XLSX, PPTX, ODT, ODS, ODP
- **Archives**: ZIP, RAR, 7Z, GZ, BZ2, XZ, TAR, ISO, DMG
- **Executables**: EXE, ELF, CLASS, SH, BAT, MACHO
- **Code**: PY, JS, TS, C, CPP, JAVA, GO, RS, PHP, RB, and many more
- **Data**: JSON, YAML, CSV, TSV, SQL, XML, HTML, and more

## Requirements

- macOS 10.15 (Catalina) or later
- Internet connection

## License

MIT License - see LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. 