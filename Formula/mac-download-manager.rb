class MacDownloadManager < Formula
  desc "Fast, intelligent command-line downloader for macOS with parallel downloads and resume capability"
  homepage "https://github.com/ArunHR26/mac-download-manager"
  version "1.0.0"
  
  # Replace with your actual GitHub username and repository
  url "https://github.com/ArunHR26/mac-download-manager/releases/download/v1.0.0/MacDownloadManager"
  sha256 "d410a8c56c785e6923fe5d7a28701238c32e07bedaea6e7cbf5d03df9fbcfc0d"
  
  depends_on :macos
  
  def install
    bin.install "MacDownloadManager" => "mac-download-manager"
  end
  
  test do
    system "#{bin}/mac-download-manager", "--help"
  end
end 