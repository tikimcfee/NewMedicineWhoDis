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

public class FileStore {
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    public func saveApplicationData(_ appData: ApplicationData) -> Error? {
        do {
            let jsonData = try jsonEncoder.encode(appData)
            try jsonData.write(to: medicineLogsDefaultFile, options: .atomic)
            return nil
        } catch {
            loge { Event(MedicineLogFileStore.self, "Encoding error : \(error)", .error) }
            return error
        }
    }

    public func loadApplicationData() -> Result<ApplicationData, Error> {
        guard medicineLogsDefaultFile.hasData else {
            logd { Event(MedicineLogFileStore.self, "No existing logs; creating new CoreAppState") }
            return .success(ApplicationData())
        }
        do {
            let appData = try Data.init(contentsOf: medicineLogsDefaultFile)
            let decodedData = try jsonDecoder.decode(ApplicationData.self, from: appData)
            return .success(decodedData)
        } catch {
            loge { Event(MedicineLogFileStore.self, "Decoding error : \(error); returning a new CoreAppState", .error) }
            return .failure(error)
        }
    }
}
