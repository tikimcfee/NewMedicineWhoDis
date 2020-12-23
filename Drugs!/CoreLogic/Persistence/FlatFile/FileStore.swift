import Foundation

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
    return directory(named: "medicineLogs")
}

private var medicineLogsDefaultFile: URL {
    return file(named: "core_logs_file.json", in: medicineLogsDirectory)
}

private var appEventLoggingFile: URL {
    return file(named: "app_event_logs.txt", in: medicineLogsDirectory)
}

public class LogFileStore {
    var logFile: URL { appEventLoggingFile }

    func cleanFile() {
        do {
            try FileManager.default.removeItem(at: logFile)
            log { Event("Log file cleared - welcome to a whole new world.") }
        } catch {
            log { Event("Log file not removed: \(error)") }
        }
    }

    func appendText(_ text: String, encoded encoding: String.Encoding = .utf8) {
        if let data = text.data(using: encoding) {
            do {
                try appendToFile(data)
            } catch {
                #if DEBUG
                fatalError("Text appending failed: \(error)")
                #endif
            }
        }
    }

    func appendToFile(_ data: Data) throws {
        let handle = try FileHandle(forUpdating: logFile)
        handle.seekToEndOfFile()
        handle.write(data)
        try handle.close()
    }
}

public class FileStore {
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    public func saveApplicationData(_ appData: ApplicationData) -> Error? {
        do {
            let jsonData = try jsonEncoder.encode(appData)
            try jsonData.write(to: medicineLogsDefaultFile, options: .atomic)
            return nil
        } catch {
            log { Event("Encoding error : \(error)", .error) }
            return error
        }
    }

    public func loadApplicationData() -> Result<ApplicationData, Error> {
        guard medicineLogsDefaultFile.hasData else {
            log { Event("No existing logs; creating new CoreAppState") }
            return .success(ApplicationData())
        }
        do {
            let appData = try Data.init(contentsOf: medicineLogsDefaultFile)
            let decodedData = try jsonDecoder.decode(ApplicationData.self, from: appData)
            return .success(decodedData)
        } catch {
            log { Event("Decoding error : \(error); returning a new CoreAppState", .error) }
            return .failure(error)
        }
    }
}
