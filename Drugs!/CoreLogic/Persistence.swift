//
//  Persistence.swift
//  Drugs!
//
//  Created by Ivan Lugo on 9/7/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import Foundation
import SwiftUI

public typealias Storable = Equatable & Hashable & Codable
public typealias SaveResult = Result<Void, Error>

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

public class MedicineLogStore {

    private let filestore = FileStore()

    func save(appState: AppState, _ handler: (Result<Void, Error>) -> Void) {
        if let error = filestore.saveAppState(appState) {
            handler(.failure(error))
        } else {
            handler(.success(()))
        }
    }

    func load(_ handler: (Result<AppState, Error>) -> Void) {
        let result = filestore.loadAppState()
        handler(result)
    }
}

public class MedicineLogOperator: ObservableObject {

    private let medicineStore: MedicineLogStore
    @ObservedObject private var coreAppState: AppState

    private let mainQueue = DispatchQueue.main
	private let saveQueue: DispatchQueue = DispatchQueue.init(
		label: "MedicineLogOperator-Queue",
		qos: .userInteractive
	)
    
    var currentEntries: [MedicineEntry] {
        return coreAppState.mainEntryList
    }
    
    init(
        medicineStore: MedicineLogStore,
        coreAppState: AppState 
    ) {
        self.medicineStore = medicineStore
        self.coreAppState = coreAppState
    }

    func addEntry(
        medicineEntry: MedicineEntry,
        _ handler: @escaping (SaveResult) -> Void
    ) {
        emit()
        coreAppState.addEntry(medicineEntry: medicineEntry)
        saveAppState(handler)
    }

    func removeEntry(
        id: String,
        _ handler: @escaping (SaveResult) -> Void
    ) {
        emit()
        coreAppState.removeEntry(id: id)
        saveAppState(handler)
    }

    private func emit() {
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
    }

    private func saveAppState(_ handler: @escaping (SaveResult) -> Void) {
        saveQueue.async {
            self.medicineStore.save(appState: self.coreAppState) { result in
                self.notifyHandler(result, handler)
            }
        }
    }

    private func notifyHandler(_ result: SaveResult, _ handler: @escaping (SaveResult) -> Void) {
        mainQueue.async {
            handler(result)
        }
    }
    
}
