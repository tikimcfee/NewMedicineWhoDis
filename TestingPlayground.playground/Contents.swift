import SwiftUI
import Combine
import Foundation
import Network
import SceneKit

// MARK: - File Operations
private let fileManager = FileManager.default

private var documentsDirectory: URL {
    let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

private func directory(named directoryName: String) -> URL {
    let directory = documentsDirectory.appendingPathComponent(directoryName, isDirectory: true)
    if !fileManager.fileExists(atPath: directory.path) {
        try! fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
    }
    return directory
}

private func file(named fileName: String, in directory: URL) -> URL {
    let fileUrl = directory.appendingPathComponent(fileName)
    if !fileManager.fileExists(atPath: fileUrl.path) {
        fileManager.createFile(atPath: fileUrl.path, contents: Data(), attributes: nil)
    }
    return fileUrl
}

extension URL {
    var hasData: Bool {
        let attributes = try? fileManager.attributesOfItem(atPath: path) as NSDictionary
        let size = attributes?.fileSize() ?? 0
        return size > 0
    }
}

// MARK: - Default file locations

private var medicineLogsDirectory: URL {
    return directory(named: "++++test_data++++")
}

private var medicineLogsDefaultFile: URL {
    return file(named: "core_logs_file.json", in: medicineLogsDirectory)
}






let testString = ""
try testString.write(
    to: medicineLogsDefaultFile.absoluteURL,
    atomically: true,
    encoding: .utf8
)

func appendToFile(_ data: Data) throws {
    let handle = try FileHandle(forUpdating: medicineLogsDefaultFile)
    handle.seekToEndOfFile()
    handle.write(data)
    try handle.close()
}

var texts = [
    "<First String>",
    "|Second String|",
    "[Third String]"
]
for i in 0..<10000 {
    texts.append(texts[i % (texts.count - 1)])
}

texts.forEach {
    do {
        if let data = $0.data(using: .utf8) {
            try appendToFile(data)
        }
    } catch {
        print(error)
    }
}



print(medicineLogsDefaultFile.absoluteString)
