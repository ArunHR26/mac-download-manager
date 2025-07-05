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

### Homebrew (Recommended)
```bash
brew install ARUNHR26/mac-download-manager/mac-download-manager
```

### Manual Installation
1. Download the latest release from [GitHub Releases](https://github.com/ARUNHR26/mac-download-manager/releases)
2. Extract and move to your PATH:
```bash
sudo mv SmartDownloader /usr/local/bin/
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