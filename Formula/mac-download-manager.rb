class MacDownloadManager < Formula
  desc "Fast, intelligent command-line downloader for macOS with parallel downloads and resume capability"
  homepage "https://github.com/ArunHR26/mac-download-manager"
  version "1.1.0"
  
  # Replace with your actual GitHub username and repository
  url "https://github.com/ArunHR26/mac-download-manager/releases/download/v1.1.0/MacDownloadManager"
  sha256 "e0168d43fe0f4d5801a5f1a453395816437f99bff8d97c80047b7bd838bc2f2c"
  
  depends_on :macos
  
  def install
    bin.install "MacDownloadManager" => "mac-download-manager"
  end
  
  test do
    system "#{bin}/mac-download-manager", "--help"
  end
end 