import Foundation

// Helper struct for chunk info
struct ChunkInfo {
    let index: Int
    let start: Int64
    let end: Int64
    let path: String
    var downloaded: Int64 {
        if let attr = try? FileManager.default.attributesOfItem(atPath: path), let size = attr[.size] as? Int64 {
            return size
        }
        return 0
    }
    var isComplete: Bool { downloaded >= (end - start + 1) }
}

class SmartDownloader: NSObject, URLSessionDownloadDelegate {
    private var downloadTasks: [URLSessionDownloadTask] = []
    private var session: URLSession!
    private var totalBytes: Int64 = 0
    private var downloadedBytes: Int64 = 0
    private var startTime: Date?
    private var outputPath: String
    private var tempDirectory: String
    private var completedChunks = 0
    private var totalChunks = 0
    private var isDownloading = false
    private var testResults: [(connections: Int, speed: Double)] = []
    private var chunkInfos: [ChunkInfo] = []
    private var lastProgressUpdate = Date()
    private var hasStartedDownloading = false
    private var initialBytesResumed: Int64 = 0
    
    init(outputPath: String) {
        self.outputPath = getUniqueFilePath(outputPath)
        self.tempDirectory = NSTemporaryDirectory() + "smart_download/"
        super.init()
        
        // Create temp directory
        try? FileManager.default.createDirectory(atPath: tempDirectory, withIntermediateDirectories: true)
    }
    
    func downloadFile(from urlString: String, userConnections: Int? = nil) {
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL.")
            return
        }
        
        print("🚀 Starting smart download...")
        print("URL: \(urlString)")
        print("Output: \(outputPath)")
        
        // Get file size first
        getFileSize(from: url) { [weak self] fileSize in
            guard let self = self else { return }
            
            if fileSize > 0 {
                self.totalBytes = fileSize
                print("📁 File size: \(self.formatBytes(fileSize))")
                
                if let userConnections = userConnections {
                    // User specified connections
                    print("👤 Using user-specified connections: \(userConnections)")
                    self.startDownload(from: url, connections: userConnections)
                } else {
                    // Auto-detect optimal connections
                    self.quickConnectionTest(url: url) { optimalConnections in
                        self.startDownload(from: url, connections: optimalConnections)
                    }
                }
            } else {
                print("⚠️  Could not determine file size, using single connection")
                self.startDownload(from: url, connections: 1)
            }
        }
    }
    
    private func getFileSize(from url: URL, completion: @escaping (Int64) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        
        let task = URLSession.shared.dataTask(with: request) { _, response, _ in
            if let httpResponse = response as? HTTPURLResponse {
                let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length")
                let fileSize = Int64(contentLength ?? "0") ?? 0
                completion(fileSize)
            } else {
                completion(0)
            }
        }
        task.resume()
    }
    
    private func quickConnectionTest(url: URL, completion: @escaping (Int) -> Void) {
        print("🔍 Quick connection speed test...")
        
        let testConnections = [1, 2, 3, 4]
        var completedTests = 0
        let group = DispatchGroup()
        
        for connections in testConnections {
            group.enter()
            testConnectionSpeed(url: url, connections: connections) { speed in
                self.testResults.append((connections: connections, speed: speed))
                completedTests += 1
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            let optimal = self.findOptimalConnections()
            print("✅ Optimal connections: \(optimal)")
            completion(optimal)
        }
    }
    
    private func testConnectionSpeed(url: URL, connections: Int, completion: @escaping (Double) -> Void) {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = connections
        let testSession = URLSession(configuration: config)
        
        // Download a larger portion (first 5MB) for more accurate speed test
        var request = URLRequest(url: url)
        request.setValue("bytes=0-5242879", forHTTPHeaderField: "Range") // First 5MB
        
        let startTime = Date()
        let task = testSession.downloadTask(with: request) { _, _, _ in
            let elapsed = Date().timeIntervalSince(startTime)
            let speed = 5242880.0 / elapsed // 5MB / time
            completion(speed)
        }
        task.resume()
    }
    
    private func findOptimalConnections() -> Int {
        guard !testResults.isEmpty else { return 2 }
        
        // Show test results
        print("📊 Connection test results:")
        let sorted = testResults.sorted { $0.speed > $1.speed }
        for result in sorted {
            let speedStr = formatBytes(Int64(result.speed)) + "/s"
            print("  \(result.connections) connection(s): \(speedStr)")
        }
        
        // Return the best
        return sorted.first?.connections ?? 2
    }
    
    private func startDownload(from url: URL, connections: Int) {
        print("📥 Starting download with \(connections) connection(s)...")
        print("⏳ Initializing download...")
        isDownloading = true
        startTime = Date()
        
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = connections
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        
        if connections > 1 {
            startParallelDownload(from: url, connections: connections)
        } else {
            startSingleDownload(from: url)
        }
    }
    
    private func startParallelDownload(from url: URL, connections: Int) {
        let chunkSize = totalBytes / Int64(connections)
        totalChunks = connections
        chunkInfos = []
        
        // Check for existing chunks and calculate initial bytes
        for i in 0..<connections {
            let startByte = Int64(i) * chunkSize
            let endByte = (i == connections - 1) ? totalBytes - 1 : startByte + chunkSize - 1
            let chunkPath = tempDirectory + "chunk_\(i)"
            let info = ChunkInfo(index: i, start: startByte, end: endByte, path: chunkPath)
            chunkInfos.append(info)
            
            if info.isComplete {
                completedChunks += 1
                initialBytesResumed += (info.end - info.start + 1)
            }
        }
        
        downloadedBytes = initialBytesResumed
        
        // Show initial progress if resuming
        if initialBytesResumed > 0 {
            print("🔄 Resuming download from \(formatBytes(initialBytesResumed))")
            updateProgress()
        }
        
        for info in chunkInfos {
            if info.isComplete {
                continue
            }
            var request = URLRequest(url: url)
            let resumeStart = info.start + info.downloaded
            request.setValue("bytes=\(resumeStart)-\(info.end)", forHTTPHeaderField: "Range")
            let task = session.downloadTask(with: request)
            downloadTasks.append(task)
            task.taskDescription = "chunk_\(info.index)"
            task.resume()
        }
        
        if completedChunks >= totalChunks {
            mergeChunks()
            exit(0)
        }
    }
    
    private func startSingleDownload(from url: URL) {
        let partialPath = tempDirectory + "single_partial"
        var resumeFrom: Int64 = 0
        if let attr = try? FileManager.default.attributesOfItem(atPath: partialPath), let size = attr[.size] as? Int64 {
            resumeFrom = size
            initialBytesResumed = size
            downloadedBytes = size
            print("🔄 Resuming download from \(formatBytes(size))")
            updateProgress()
        }
        var request = URLRequest(url: url)
        if resumeFrom > 0 {
            request.setValue("bytes=\(resumeFrom)-", forHTTPHeaderField: "Range")
        }
        let task = session.downloadTask(with: request)
        downloadTasks.append(task)
        task.taskDescription = "single"
        task.resume()
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if downloadTasks.count > 1 {
            // Parallel download
            let chunkIndex = Int(downloadTask.taskDescription?.split(separator: "_").last ?? "0") ?? 0
            let info = chunkInfos[chunkIndex]
            let chunkPath = info.path
            // Append to existing chunk if resuming
            if FileManager.default.fileExists(atPath: chunkPath) {
                if let handle = try? FileHandle(forWritingTo: URL(fileURLWithPath: chunkPath)),
                   let data = try? Data(contentsOf: location) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    try? handle.close()
                }
            } else {
                try? FileManager.default.moveItem(atPath: location.path, toPath: chunkPath)
            }
            completedChunks += 1
            downloadedBytes += (info.end - info.start + 1) - info.downloaded
            updateProgress()
            if completedChunks >= totalChunks {
                mergeChunks()
                exit(0)
            }
        } else {
            // Single download
            let partialPath = tempDirectory + "single_partial"
            // Append to existing partial if resuming
            if FileManager.default.fileExists(atPath: partialPath) {
                if let handle = try? FileHandle(forWritingTo: URL(fileURLWithPath: partialPath)),
                   let data = try? Data(contentsOf: location) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    try? handle.close()
                }
            } else {
                try? FileManager.default.moveItem(atPath: location.path, toPath: partialPath)
            }
            // Move/rename to final output
            try? FileManager.default.moveItem(atPath: partialPath, toPath: outputPath)
            
            // Fix file extension based on content
            let finalPath = fixFileExtension(outputPath)
            print("\n✅ Download completed: \(finalPath)")
            exit(0)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        // Mark that download has actually started
        if !hasStartedDownloading {
            hasStartedDownloading = true
            print("🚀 Download started!")
        }
        
        if downloadTasks.count == 1 {
            // Single download progress
            downloadedBytes = totalBytesWritten + initialBytesResumed
            totalBytes = totalBytesExpectedToWrite + initialBytesResumed
            updateProgress()
        } else {
            // Parallel download progress - update based on chunk completion
            let chunkIndex = Int(downloadTask.taskDescription?.split(separator: "_").last ?? "0") ?? 0
            if chunkIndex < chunkInfos.count {
                let info = chunkInfos[chunkIndex]
                let chunkProgress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                let chunkSize = info.end - info.start + 1
                let chunkDownloaded = Int64(Double(chunkSize) * chunkProgress)
                
                // Update total progress
                downloadedBytes = chunkInfos.enumerated().reduce(0) { sum, element in
                    let (index, info) = element
                    if index == chunkIndex {
                        return sum + chunkDownloaded
                    } else {
                        return sum + info.downloaded
                    }
                }
                updateProgress()
            }
        }
    }
    
    private func getChunkSize(_ task: URLSessionDownloadTask) -> Int64 {
        guard let response = task.response as? HTTPURLResponse,
              let rangeHeader = response.value(forHTTPHeaderField: "Content-Range") else {
            return 0
        }
        
        // Parse "bytes start-end/total" format
        let components = rangeHeader.components(separatedBy: " ")
        guard components.count >= 2 else { return 0 }
        
        let rangePart = components[1]
        let rangeComponents = rangePart.components(separatedBy: "/")
        guard rangeComponents.count >= 1 else { return 0 }
        
        let byteRange = rangeComponents[0]
        let byteComponents = byteRange.components(separatedBy: "-")
        guard byteComponents.count >= 2,
              let start = Int64(byteComponents[0]),
              let end = Int64(byteComponents[1]) else { return 0 }
        
        return end - start + 1
    }
    
    private func updateProgress() {
        guard totalBytes > 0 else { return }
        
        // Throttle progress updates to avoid overwhelming output
        let now = Date()
        if now.timeIntervalSince(lastProgressUpdate) < 0.1 { return }
        lastProgressUpdate = now
        
        let percentage = min(Double(downloadedBytes) / Double(totalBytes) * 100, 100.0)
        let speed = calculateSpeed()
        let eta = calculateETA()
        
        let downloadedStr = formatBytes(downloadedBytes)
        let speedStr = speed
        
        print("\r📊 Progress: \(String(format: "%.1f", percentage))% | \(downloadedStr)/\(formatBytes(totalBytes)) | Speed: \(speedStr) | ETA: \(eta)", terminator: "")
        fflush(stdout)
    }
    
    private func calculateSpeed() -> String {
        guard let startTime = startTime, downloadedBytes > initialBytesResumed else { 
            return hasStartedDownloading ? "Starting..." : "0 B/s" 
        }
        let elapsed = Date().timeIntervalSince(startTime)
        guard elapsed > 0 else { return "0 B/s" }
        let actualDownloaded = downloadedBytes - initialBytesResumed
        let speed = Double(actualDownloaded) / elapsed
        guard speed > 0 else { return "0 B/s" }
        return formatBytes(Int64(speed)) + "/s"
    }
    
    private func calculateETA() -> String {
        guard let startTime = startTime, totalBytes > 0, downloadedBytes > initialBytesResumed else { 
            return hasStartedDownloading ? "Calculating..." : "Unknown" 
        }
        let elapsed = Date().timeIntervalSince(startTime)
        guard elapsed > 0 else { return "Unknown" }
        let actualDownloaded = downloadedBytes - initialBytesResumed
        let speed = Double(actualDownloaded) / elapsed
        guard speed > 0 else { return "Unknown" }
        let remainingBytes = totalBytes - downloadedBytes
        let etaSeconds = Double(remainingBytes) / speed
        
        if etaSeconds.isInfinite || etaSeconds.isNaN || etaSeconds < 0 {
            return "Unknown"
        }
        
        if etaSeconds < 1 {
            return "00:00"
        }
        
        let minutes = Int(etaSeconds) / 60
        let seconds = Int(etaSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func mergeChunks() {
        print("\n🔧 Merging chunks...")
        FileManager.default.createFile(atPath: outputPath, contents: nil)
        guard let outputFile = FileHandle(forWritingAtPath: outputPath) else {
            print("❌ Error: Could not create output file")
            return
        }
        defer { try? outputFile.close() }
        for info in chunkInfos.sorted(by: { $0.index < $1.index }) {
            if let chunkData = FileManager.default.contents(atPath: info.path) {
                outputFile.write(chunkData)
            }
        }
        // Clean up temp files
        for info in chunkInfos {
            try? FileManager.default.removeItem(atPath: info.path)
        }
        try? FileManager.default.removeItem(atPath: tempDirectory)
        
        // Fix file extension based on content
        let finalPath = fixFileExtension(outputPath)
        print("✅ Download completed: \(finalPath)")
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func fixFileExtension(_ filePath: String) -> String {
        guard let data = FileManager.default.contents(atPath: filePath) else { return filePath }
        
        // Check file signatures (magic numbers)
        let fileExtension = detectFileType(from: data)
        
        if let detectedExtension = fileExtension {
            let url = URL(fileURLWithPath: filePath)
            let directory = url.deletingLastPathComponent().path
            let filename = url.deletingPathExtension().lastPathComponent
            let newPath = "\(directory)/\(filename).\(detectedExtension)"
            
            // Only rename if the extension is different
            if filePath != newPath {
                try? FileManager.default.moveItem(atPath: filePath, toPath: newPath)
                print("📝 Detected file type: \(detectedExtension.uppercased())")
                return newPath
            }
        }
        
        return filePath
    }
    
    private func detectFileType(from data: Data) -> String? {
        guard data.count >= 4 else { return nil }
        let bytes = [UInt8](data.prefix(32))
        // Video
        if bytes.starts(with: [0x00,0x00,0x00]) && bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70 { return "mp4" }
        if bytes[0] == 0x1A && bytes[1] == 0x45 && bytes[2] == 0xDF && bytes[3] == 0xA3 { return "mkv" }
        if bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 && bytes[8] == 0x41 && bytes[9] == 0x56 && bytes[10] == 0x49 { return "avi" }
        if bytes[4] == 0x6D && bytes[5] == 0x6F && bytes[6] == 0x6F && bytes[7] == 0x76 { return "mov" }
        if bytes[0] == 0x1A && bytes[1] == 0x45 && bytes[2] == 0xDF && bytes[3] == 0xA3 { return "webm" }
        // Audio
        if bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33 { return "mp3" }
        if bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0 { return "mp3" }
        if bytes[0] == 0x66 && bytes[1] == 0x4C && bytes[2] == 0x61 && bytes[3] == 0x43 { return "flac" }
        if bytes[0] == 0x4F && bytes[1] == 0x67 && bytes[2] == 0x67 && bytes[3] == 0x53 { return "ogg" }
        if bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 && bytes[8] == 0x57 && bytes[9] == 0x41 && bytes[10] == 0x56 && bytes[11] == 0x45 { return "wav" }
        if bytes[0] == 0x00 && bytes[1] == 0x00 && bytes[2] == 0x00 && (bytes[4] == 0x6D && bytes[5] == 0x64 && bytes[6] == 0x61 && bytes[7] == 0x74) { return "m4a" }
        if bytes[0] == 0x30 && bytes[1] == 0x26 && bytes[2] == 0xB2 && bytes[3] == 0x75 { return "wma" }
        if bytes[0] == 0xFF && (bytes[1] & 0xF6) == 0xF0 { return "aac" }
        // Image
        if bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 { return "png" }
        if bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF { return "jpg" }
        if bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 { return "gif" }
        if bytes[0] == 0x42 && bytes[1] == 0x4D { return "bmp" }
        if bytes[0] == 0x49 && bytes[1] == 0x49 && bytes[2] == 0x2A && bytes[3] == 0x00 { return "tif" }
        if bytes[0] == 0x4D && bytes[1] == 0x4D && bytes[2] == 0x00 && bytes[3] == 0x2A { return "tif" }
        if bytes[0] == 0x00 && bytes[1] == 0x00 && bytes[2] == 0x01 && bytes[3] == 0x00 { return "ico" }
        if bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 && bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50 { return "webp" }
        if bytes[0] == 0x00 && bytes[1] == 0x18 && bytes[2] == 0x0C && bytes[3] == 0x0A { return "heic" }
        // Document
        if bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46 { return "pdf" }
        if bytes[0] == 0xD0 && bytes[1] == 0xCF && bytes[2] == 0x11 && bytes[3] == 0xE0 { return "doc" } // or xls, ppt
        if bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04 {
            // OOXML: docx, xlsx, pptx, odt, ods, odp, epub, jar, apk, zip
            if let str = String(data: data.prefix(100), encoding: .ascii) {
                if str.contains("[Content_Types].xml") { return "docx" }
                if str.contains("xl/") { return "xlsx" }
                if str.contains("ppt/") { return "pptx" }
                if str.contains("mimetypeapplication/epub+zip") { return "epub" }
                if str.contains("META-INF/MANIFEST.MF") { return "jar" }
                if str.contains("AndroidManifest.xml") { return "apk" }
                if str.contains("mimetypeapplication/vnd.oasis.opendocument.text") { return "odt" }
                if str.contains("mimetypeapplication/vnd.oasis.opendocument.spreadsheet") { return "ods" }
                if str.contains("mimetypeapplication/vnd.oasis.opendocument.presentation") { return "odp" }
            }
            return "zip"
        }
        if bytes[0] == 0x52 && bytes[1] == 0x61 && bytes[2] == 0x72 && bytes[3] == 0x21 { return "rar" }
        if bytes[0] == 0x37 && bytes[1] == 0x7A && bytes[2] == 0xBC && bytes[3] == 0xAF { return "7z" }
        if bytes[0] == 0x1F && bytes[1] == 0x8B { return "gz" }
        if bytes[0] == 0x42 && bytes[1] == 0x5A && bytes[2] == 0x68 { return "bz2" }
        if bytes[0] == 0xFD && bytes[1] == 0x37 && bytes[2] == 0x7A && bytes[3] == 0x58 { return "xz" }
        if bytes[0] == 0x75 && bytes[1] == 0x73 && bytes[2] == 0x74 && bytes[3] == 0x61 && bytes[4] == 0x72 { return "tar" }
        if bytes[0] == 0x43 && bytes[1] == 0x44 && bytes[2] == 0x30 && bytes[3] == 0x30 { return "iso" }
        if bytes[0] == 0x78 && bytes[1] == 0x01 { return "dmg" }
        // Executable
        if bytes[0] == 0x4D && bytes[1] == 0x5A { return "exe" }
        if bytes[0] == 0x7F && bytes[1] == 0x45 && bytes[2] == 0x4C && bytes[3] == 0x46 { return "elf" }
        if bytes[0] == 0xCA && bytes[1] == 0xFE && bytes[2] == 0xBA && bytes[3] == 0xBE { return "class" }
        if bytes[0] == 0x23 && bytes[1] == 0x21 { return "sh" }
        if bytes[0] == 0xFF && bytes[1] == 0xFE { return "bat" }
        if bytes[0] == 0xCF && bytes[1] == 0xFA && bytes[2] == 0xED && bytes[3] == 0xFE { return "macho" }
        // Other
        if bytes[0] == 0x38 && bytes[1] == 0x42 && bytes[2] == 0x50 && bytes[3] == 0x53 { return "psd" }
        if bytes[0] == 0x25 && bytes[1] == 0x21 { return "ps" }
        if bytes[0] == 0xD0 && bytes[1] == 0xCF && bytes[2] == 0x11 && bytes[3] == 0xE0 { return "msg" }
        if bytes[0] == 0x21 && bytes[1] == 0x3C && bytes[2] == 0x61 && bytes[3] == 0x72 && bytes[4] == 0x63 && bytes[5] == 0x68 && bytes[6] == 0x3E { return "deb" }
        if bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04 { return "jar" }
        if bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04 { return "apk" }
        if bytes[0] == 0x62 && bytes[1] == 0x70 && bytes[2] == 0x6C && bytes[3] == 0x69 && bytes[4] == 0x73 && bytes[5] == 0x74 { return "plist" }
        if bytes[0] == 0x53 && bytes[1] == 0x51 && bytes[2] == 0x4C && bytes[3] == 0x69 { return "sqlite" }
        if bytes[0] == 0x00 && bytes[1] == 0x01 && bytes[2] == 0x00 && bytes[3] == 0x00 { return "ttf" }
        if bytes[0] == 0x4F && bytes[1] == 0x54 && bytes[2] == 0x54 && bytes[3] == 0x4F { return "otf" }
        if bytes[0] == 0x00 && bytes[1] == 0x00 && bytes[2] == 0x01 && bytes[3] == 0x00 { return "ico" }
        if bytes[0] == 0x3C && bytes[1] == 0x3F && bytes[2] == 0x78 && bytes[3] == 0x6D && bytes[4] == 0x6C { return "xml" }
        if bytes[0] == 0x7B && bytes[1] == 0x0A { return "json" }
        if bytes[0] == 0x3C && bytes[1] == 0x21 && bytes[2] == 0x44 && bytes[3] == 0x4F && bytes[4] == 0x43 && bytes[5] == 0x54 && bytes[6] == 0x59 && bytes[7] == 0x50 && bytes[8] == 0x45 { return "html" }
        if bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF { return "txt" }
        if bytes[0] == 0xFF && bytes[1] == 0xFE { return "txt" }
        if bytes[0] == 0xFE && bytes[1] == 0xFF { return "txt" }
        if bytes[0] == 0x00 && bytes[1] == 0x00 && bytes[2] == 0xFE && bytes[3] == 0xFF { return "txt" }
        // --- Heuristic detection for text/config/data files ---
        if let str = String(data: data.prefix(2048), encoding: .utf8) {
            let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
            // Python
            if trimmed.hasPrefix("#!/") && trimmed.contains("python") { return "py" }
            if trimmed.hasPrefix("# -*- coding:") { return "py" }
            // Jupyter Notebook
            if trimmed.hasPrefix("{") && trimmed.contains("cells") && trimmed.contains("nbformat") { return "ipynb" }
            // JSON
            if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") { return "json" }
            // YAML
            if trimmed.hasPrefix("---") || trimmed.contains(": ") { return "yaml" }
            // CSV/TSV
            if trimmed.contains(",") && trimmed.contains("\n") { return "csv" }
            if trimmed.contains("\t") && trimmed.contains("\n") { return "tsv" }
            // Markdown
            if trimmed.contains("# ") || trimmed.contains("## ") || trimmed.contains("- ") { return "md" }
            // SQL
            if trimmed.lowercased().contains("select ") || trimmed.lowercased().contains("create table") { return "sql" }
            // HTML/XML
            if trimmed.hasPrefix("<html") || trimmed.hasPrefix("<!DOCTYPE html") { return "html" }
            if trimmed.hasPrefix("<?xml") { return "xml" }
            // INI/CFG/CONF
            if trimmed.contains("=") && (trimmed.contains("[section]") || trimmed.contains("[main]") || trimmed.contains("[DEFAULT]")) { return "ini" }
            if trimmed.contains("=") && (trimmed.contains(".conf") || trimmed.contains(".cfg")) { return "conf" }
            // TOML
            if trimmed.contains("[tool.") || trimmed.contains("[package]") { return "toml" }
            // R
            if trimmed.hasPrefix("# R") || trimmed.contains("<- function(") { return "r" }
            // Shell
            if trimmed.hasPrefix("#!/bin/bash") || trimmed.hasPrefix("#!/bin/sh") || trimmed.hasPrefix("#!/usr/bin/env bash") { return "sh" }
            // JavaScript/TypeScript
            if trimmed.contains("function ") || trimmed.contains("const ") || trimmed.contains("let ") { return "js" }
            if trimmed.contains("import ") && trimmed.contains("from ") { return "js" }
            if trimmed.contains(": string") || trimmed.contains(": number") { return "ts" }
            // C/C++/Header
            if trimmed.contains("#include") || trimmed.contains("int main(") { return "c" }
            if trimmed.contains("#include <iostream>") { return "cpp" }
            if trimmed.contains("#ifndef") && trimmed.contains("#define") { return "h" }
            // Java
            if trimmed.contains("public class ") { return "java" }
            // Scala
            if trimmed.contains("object ") && trimmed.contains("extends App") { return "scala" }
            // Go
            if trimmed.contains("package main") && trimmed.contains("func main(") { return "go" }
            // Rust
            if trimmed.contains("fn main()") && trimmed.contains("extern crate") { return "rs" }
            // PHP
            if trimmed.hasPrefix("<?php") { return "php" }
            // Ruby
            if trimmed.hasPrefix("#!/usr/bin/env ruby") || trimmed.contains("def ") { return "rb" }
            // Perl
            if trimmed.hasPrefix("#!/usr/bin/perl") { return "pl" }
            // Swift
            if trimmed.contains("import Foundation") && trimmed.contains("func ") { return "swift" }
            // Kotlin
            if trimmed.contains("fun main(") && trimmed.contains(": String") { return "kt" }
            // Dart
            if trimmed.contains("void main()") && trimmed.contains("import 'dart:") { return "dart" }
            // Lua
            if trimmed.contains("function ") && trimmed.contains("end") { return "lua" }
            // Assembly
            if trimmed.contains("section .text") || trimmed.contains("global _start") { return "asm" }
            // Data science: pickle, joblib, npy, npz, h5, mat, feather, parquet, orc, avro, rds, rdata
            if trimmed.contains("NumPy format") { return "npy" }
            if trimmed.contains("PKL") || trimmed.contains("pickle") { return "pkl" }
            if trimmed.contains("joblib") { return "joblib" }
            if trimmed.contains("HDF5") { return "h5" }
            if trimmed.contains("MATLAB 5.0 MAT-file") { return "mat" }
            if trimmed.contains("FEATHER") { return "feather" }
            if trimmed.contains("PAR1") { return "parquet" }
            if trimmed.contains("ORC") { return "orc" }
            if trimmed.contains("Objavro") { return "avro" }
            if trimmed.contains("RDX2") { return "rds" }
            if trimmed.contains("RData") { return "rdata" }
            // Log
            if trimmed.lowercased().contains("error") || trimmed.lowercased().contains("warn") || trimmed.lowercased().contains("info") { return "log" }
            // CSV/TSV fallback
            if trimmed.contains(",") { return "csv" }
            if trimmed.contains("\t") { return "tsv" }
        }
        return nil
    }

    func cancel() {
        if isDownloading {
            downloadTasks.forEach { $0.cancel() }
            print("\n❌ Download cancelled")
            exit(1)
        }
    }
}

// Helper function to generate unique file paths
func getUniqueFilePath(_ originalPath: String) -> String {
    let fileManager = FileManager.default
    
    // If file doesn't exist, return original path
    if !fileManager.fileExists(atPath: originalPath) {
        return originalPath
    }
    
    // Split path into directory, filename, and extension
    let url = URL(fileURLWithPath: originalPath)
    let directory = url.deletingLastPathComponent().path
    let filename = url.deletingPathExtension().lastPathComponent
    let fileExtension = url.pathExtension
    
    var counter = 1
    var newPath: String
    
    repeat {
        if fileExtension.isEmpty {
            newPath = "\(directory)/\(filename) copy \(counter)"
        } else {
            newPath = "\(directory)/\(filename) copy \(counter).\(fileExtension)"
        }
        counter += 1
    } while fileManager.fileExists(atPath: newPath)
    
    return newPath
}

var globalDownloader: SmartDownloader?

func signalHandler(signal: Int32) {
    globalDownloader?.cancel()
}

func extractFilenameFromURL(_ urlString: String) -> String {
    guard let url = URL(string: urlString) else { return "downloaded_file" }
    let lastComponent = url.lastPathComponent
    return lastComponent.isEmpty ? "downloaded_file" : lastComponent
}

func main() {
    let args = CommandLine.arguments
    
    // Handle help flag
    if args.contains("--help") || args.contains("-h") {
        print("🚀 Mac Download Manager v1.0.0")
        print("")
        print("Usage: mac-download-manager <URL> [options]")
        print("")
        print("Options:")
        print("  -o, --output <file>     Specify output filename")
        print("  -c, --connections <n>   Specify number of connections (1-8)")
        print("  -h, --help             Show this help message")
        print("")
        print("Examples:")
        print("  mac-download-manager https://example.com/file.zip")
        print("  mac-download-manager https://example.com/file.zip -o myfile.zip")
        print("  mac-download-manager https://example.com/file.zip -c 4")
        print("  mac-download-manager https://example.com/file.zip -o myfile.zip -c 4")
        print("")
        print("Features:")
        print("- Smart connection optimization")
        print("- Parallel downloads with resume support")
        print("- Progress tracking with speed and ETA")
        print("- File type detection")
        print("- Ctrl+C to cancel")
        return
    }
    
    // Parse arguments
    var url: String?
    var output: String?
    var userConnections: Int?
    
    var i = 1
    while i < args.count {
        let arg = args[i]
        
        switch arg {
        case "-o", "--output":
            if i + 1 < args.count {
                output = args[i + 1]
                i += 2
            } else {
                print("❌ Error: -o/--output requires a filename")
                return
            }
        case "-c", "--connections":
            if i + 1 < args.count {
                if let connections = Int(args[i + 1]) {
                    userConnections = connections
                    i += 2
                } else {
                    print("❌ Error: -c/--connections requires a number")
                    return
                }
            } else {
                print("❌ Error: -c/--connections requires a number")
                return
            }
        case "-h", "--help":
            // Already handled above
            return
        default:
            if arg.hasPrefix("-") {
                print("❌ Error: Unknown option '\(arg)'")
                print("Use --help for usage information")
                return
            } else if url == nil {
                url = arg
                i += 1
            } else {
                print("❌ Error: Multiple URLs specified")
                return
            }
        }
    }
    
    guard let url = url else {
        print("❌ Error: URL is required")
        print("Use --help for usage information")
        return
    }
    
    // Set default output filename if not specified
    let finalOutput = output ?? extractFilenameFromURL(url)
    
    globalDownloader = SmartDownloader(outputPath: finalOutput)
    
    // Handle Ctrl+C for cancellation
    signal(SIGINT, signalHandler)
    
    globalDownloader?.downloadFile(from: url, userConnections: userConnections)
    
    // Keep the program running
    RunLoop.main.run()
}

main() 