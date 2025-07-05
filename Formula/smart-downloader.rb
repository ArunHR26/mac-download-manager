class SmartDownloader < Formula
  desc "Fast, intelligent command-line downloader for macOS with parallel downloads and resume capability"
  homepage "https://github.com/ARUNHR26/mac-download-manager"
  version "1.0.0"
  
  # Replace with your actual GitHub username and repository
  url "https://github.com/ARUNHR26/mac-download-manager/releases/download/v1.0.0/SmartDownloader"
  sha256 "REPLACE_WITH_ACTUAL_SHA256"
  
  depends_on :macos
  
  def install
    bin.install "SmartDownloader"
  end
  
  test do
    system "#{bin}/SmartDownloader", "--help"
  end
end 