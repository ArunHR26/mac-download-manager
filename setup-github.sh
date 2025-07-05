#!/bin/bash

# GitHub Setup Script for Smart Downloader
echo "🚀 Setting up GitHub repository for Smart Downloader"

# Check if git is initialized
if [ ! -d ".git" ]; then
    echo "❌ Git repository not initialized. Please run 'git init' first."
    exit 1
fi

# Add all files
echo "📁 Adding files to git..."
git add .

# Initial commit
echo "💾 Creating initial commit..."
git commit -m "Initial commit: Smart Downloader CLI tool

- Fast parallel downloads with auto-connection optimization
- Resume capability for interrupted downloads
- Real-time progress tracking with speed and ETA
- Automatic file type detection and extension fixing
- Duplicate file protection with copy suffixes"

echo "✅ Initial commit created!"
echo ""
echo "📋 Next steps:"
echo "1. Create a new repository on GitHub: https://github.com/new"
echo "2. Repository name: smart-downloader (or your preferred name)"
echo "3. Make it PUBLIC (required for Homebrew)"
echo "4. Don't initialize with README (we already have one)"
echo "5. Copy the repository URL and run:"
echo "   git remote add origin https://github.com/ARUNHR26/mac-download-manager.git"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "6. Create a release:"
echo "   - Go to your repository on GitHub"
echo "   - Click 'Releases' → 'Create a new release'"
echo "   - Tag: v1.0.0"
echo "   - Title: Smart Downloader v1.0.0"
echo "   - Upload the binary: .build/release/SmartDownloader"
echo ""
echo "7. Update the Homebrew formula with your actual GitHub username and SHA256" 