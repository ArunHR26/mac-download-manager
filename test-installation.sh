#!/bin/bash

# Test Installation Script for Mac Download Manager
echo "🧪 Testing Mac Download Manager Installation"

echo "1. Testing direct download..."
curl -L -o test-binary https://github.com/ArunHR26/mac-download-manager/releases/download/v1.0.0/MacDownloadManager
if [ $? -eq 0 ]; then
    echo "✅ Direct download successful"
    chmod +x test-binary
    echo "📊 Downloaded binary size: $(ls -lh test-binary | awk '{print $5}')"
    echo "🔍 Downloaded SHA256: $(shasum -a 256 test-binary | awk '{print $1}')"
    echo "🧪 Testing downloaded binary..."
    ./test-binary
    rm test-binary
else
    echo "❌ Direct download failed - release may not be published yet"
fi

echo ""
echo "2. Testing Homebrew installation..."
brew install ArunHR26/mac-download-manager/mac-download-manager
if [ $? -eq 0 ]; then
    echo "✅ Homebrew installation successful"
    echo "🧪 Testing installed binary..."
    mac-download-manager
    echo ""
    echo "🎉 Installation test completed successfully!"
    echo "Users can now install with: brew install ArunHR26/mac-download-manager/mac-download-manager"
else
    echo "❌ Homebrew installation failed"
    echo "Make sure the GitHub release is published first"
fi 