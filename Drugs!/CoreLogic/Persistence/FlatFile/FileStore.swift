import Foundation

// MARK: - File Operations
public struct AppFiles {
    
    private static let fileManager = FileManager.default
    
    private static var documentsDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    public static func directory(named directoryName: String) -> URL {
        let directory = documentsDirectory.appendingPathComponent(directoryName, isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try! fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        }
        return directory
    }
    
    public static func file(named fileName: String, in directory: URL) -> URL {
        let fileUrl = directory.appendingPathComponent(fileName)
        if !fileManager.fileExists(atPath: fileUrl.path) {
            fileManager.createFile(atPath: fileUrl.path, contents: Data(), attributes: nil)
        }
        return fileUrl
    }
}

// MARK: - Default file locations
extension AppFiles {
    // Flat files
    public static var medicineLogsDirectory: URL {
        directory(named: "medicineLogs")
    }
    
    public static var medicineLogsFile: URL {
        file(named: "core_logs_file.json", in: medicineLogsDirectory)
    }
    
    public static var appEventLogging: URL {
        file(named: "app_event_logs.txt", in: medicineLogsDirectory)
    }
    
    // Realm files
    public static var realmsDirectory: URL {
        directory(named: "logs-in-realms")
    }
    
    public static var entryLogRealm: URL {
        file(named: "realmfile_entry_log", in: realmsDirectory)
    }
    
    #if DEBUG
    public static var Testing__entryLogRealm: URL {
        file(named: "TESTS__realmfile_entry_log__TESTS", in: realmsDirectory)
    }
    #endif
}

public class LogFileStore {
    var logFile: URL { AppFiles.appEventLogging }

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
    
    let targetFile: URL
    
    public init(
        targetFile: URL = AppFiles.medicineLogsFile
    ) {
        self.targetFile = targetFile
    }

    public func saveApplicationData(_ appData: ApplicationData) -> Error? {
        do {
            let jsonData = try jsonEncoder.encode(appData)
            try jsonData.write(to: targetFile, options: .atomic)
            return nil
        } catch {
            log { Event("Encoding error : \(error)", .error) }
            return error
        }
    }

    public func loadApplicationData() -> Result<ApplicationData, Error> {
        guard targetFile.hasData else {
            log { Event("No existing logs; creating new CoreAppState") }
            return .success(ApplicationData())
        }
        do {
            let appData = try Data.init(contentsOf: targetFile)
            let decodedData = try jsonDecoder.decode(ApplicationData.self, from: appData)
            return .success(decodedData)
        } catch {
            log { Event("Decoding error : \(error); returning a new CoreAppState", .error) }
            return .failure(error)
        }
    }
}

extension URL {
    var hasData: Bool {
        let attributes = try? FileManager.default.attributesOfItem(atPath: path) as NSDictionary
        let size = attributes?.fileSize() ?? 0
        return size > 0
    }
}
