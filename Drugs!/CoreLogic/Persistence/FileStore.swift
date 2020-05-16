import Foundation

public class FileStore {
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()
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

    private var medicineLogsDirectory: URL {
        return directory(named: "medicineLogs")
    }

    private var medicineLogsDefaultFile: URL {
        return file(named: "core_logs_file.json", in: medicineLogsDirectory)
    }

    private var medicineLogsDefaultFileIsEmpty: Bool {
        let attributes = try? fileManager.attributesOfItem(atPath: medicineLogsDefaultFile.path) as NSDictionary
        let size = attributes?.fileSize() ?? 0
        return size <= 0
    }

    public func saveAppState(_ appState: AppState) -> Error? {
        do {
            let jsonData = try jsonEncoder.encode(appState)
            try jsonData.write(to: medicineLogsDefaultFile, options: .atomic)
            return nil
        } catch {
            loge { Event(MedicineLogStore.self, "Encoding error : \(error)", .error) }
            return error
        }
    }

    public func loadAppState() -> Result<AppState, Error> {
        if medicineLogsDefaultFileIsEmpty {
            logd { Event(MedicineLogStore.self, "No existing logs; creating new CoreAppState") }
            return .success(AppState())
        }
        do {
            let stateData = try Data.init(contentsOf: medicineLogsDefaultFile)
            let decodedState = try jsonDecoder.decode(AppState.self, from: stateData)
            return .success(decodedState)
        } catch {
            loge { Event(MedicineLogStore.self, "Decoding error : \(error); returning a new CoreAppState", .error) }
            return .failure(error)
        }
    }
}
