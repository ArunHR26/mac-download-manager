#!/bin/bash

# Homebrew Tap Setup Script for Mac Download Manager
echo "🍺 Setting up Homebrew tap for Mac Download Manager"

# Check if we have the formula file
if [ ! -f "Formula/mac-download-manager.rb" ]; then
    echo "❌ Formula file not found: Formula/mac-download-manager.rb"
    exit 1
fi

echo "📋 Instructions for setting up Homebrew tap:"
echo ""
echo "1. Create a new GitHub repository:"
echo "   - Go to: https://github.com/new"
echo "   - Repository name: homebrew-mac-download-manager"
echo "   - Make it PUBLIC"
echo "   - Don't initialize with README"
echo "   - Click 'Create repository'"
echo ""
echo "2. Clone the tap repository:"
echo "   git clone https://github.com/ArunHR26/homebrew-mac-download-manager.git"
echo "   cd homebrew-mac-download-manager"
echo ""
echo "3. Copy the formula file:"
echo "   cp ../Formula/mac-download-manager.rb ."
echo ""
echo "4. Commit and push:"
echo "   git add mac-download-manager.rb"
echo "   git commit -m 'Add Mac Download Manager formula'"
echo "   git push origin main"
echo ""
echo "5. Test the installation:"
echo "   brew install ArunHR26/mac-download-manager/mac-download-manager"
echo ""
echo "✅ After completing these steps, users can install with:"
echo "   brew install ArunHR26/mac-download-manager/mac-download-manager" 