#!/bin/bash

# GitHub Release Creation Script for Mac Download Manager
echo "🚀 Creating GitHub Release for Mac Download Manager"

# Check if binary exists
if [ ! -f ".build/release/MacDownloadManager" ]; then
    echo "❌ Binary not found: .build/release/MacDownloadManager"
    echo "Please run: swift build -c release"
    exit 1
fi

echo "✅ Binary found: .build/release/MacDownloadManager"
echo "📊 Binary size: $(ls -lh .build/release/MacDownloadManager | awk '{print $5}')"
echo "🔍 SHA256: $(shasum -a 256 .build/release/MacDownloadManager | awk '{print $1}')"
echo ""

echo "📋 Manual Release Creation Steps:"
echo ""
echo "1. Go to: https://github.com/ArunHR26/mac-download-manager/releases"
echo "2. Click 'Create a new release'"
echo ""
echo "3. Fill in the details:"
echo "   - Tag: v1.0.0"
echo "   - Title: Mac Download Manager v1.0.0"
echo ""
echo "4. Description (copy this):"
echo "---"
echo "Initial release of Mac Download Manager CLI tool"
echo ""
echo "Features:"
echo "- Fast parallel downloads with auto-connection optimization"
echo "- Resume capability for interrupted downloads"
echo "- Real-time progress tracking with speed and ETA"
echo "- Automatic file type detection and extension fixing"
echo "- Duplicate file protection with copy suffixes"
echo ""
echo "Installation:"
echo "brew install ArunHR26/mac-download-manager/mac-download-manager"
echo "---"
echo ""
echo "5. Upload binary:"
echo "   - Drag and drop: .build/release/MacDownloadManager"
echo "   - OR click 'Attach binaries by dropping them here'"
echo ""
echo "6. Click 'Publish release'"
echo ""
echo "7. After release is published, test Homebrew:"
echo "   brew install ArunHR26/mac-download-manager/mac-download-manager"
echo ""
echo "✅ Release URL will be:"
echo "   https://github.com/ArunHR26/mac-download-manager/releases/download/v1.0.0/MacDownloadManager" 