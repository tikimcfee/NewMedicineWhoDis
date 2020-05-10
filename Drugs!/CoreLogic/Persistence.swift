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

public class MedicineLogStore {
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
        let attributes = try? fileManager.attributesOfItem(atPath: medicineLogsDefaultFile.absoluteString) as NSDictionary
        let size = attributes?.fileSize() ?? 0
        return size <= 0
    }
}

extension MedicineLogStore {
    func save(appState: AppState) -> Bool {
        do {
            let jsonData = try jsonEncoder.encode(appState)
            try jsonData.write(to: medicineLogsDefaultFile)
            return true
        } catch {
            loge { Event(MedicineLogStore.self, "Encoding error : \(error)", .error) }
            return false
        }
    }

    func load() -> AppState {
        if medicineLogsDefaultFileIsEmpty {
            logd { Event(MedicineLogStore.self, "No existing logs; creating new CoreAppState") }
            return AppState()
        }
        do {
            let stateData = try Data.init(contentsOf: medicineLogsDefaultFile)
            return try jsonDecoder.decode(AppState.self, from: stateData)
        } catch {
            loge { Event(MedicineLogStore.self, "Decoding error : \(error); returning a new CoreAppState", .error) }
            return AppState()
        }
    }
}

/// This whole 'LogStore' and 'Operator' thing is getting annoying.. make it better
/// - Why is there an Operator and an AppState? Is it really so important to separate the code?

public class MedicineLogOperator: ObservableObject {
    
    private let medicineStore: MedicineLogStore
    @Published private var coreAppState: AppState
	
	private let queue: DispatchQueue = DispatchQueue.init(
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
    
    func addEntry(medicineEntry: MedicineEntry) {
        onQueue {
            self.coreAppState.addEntry(medicineEntry: medicineEntry)
        }
    }
    
    func removeEntry(id: String) {
		onQueue {
            self.coreAppState.removeEntry(id: id)
        }
    }
    
	private func onQueue(_ operation: @escaping () -> Void) { /// Is the operation thing really necessary? I guess it let's us skip action if we want
        queue.async {
            self.emit()
            operation()
            let didSucceed = self.medicineStore.save(appState: self.coreAppState)
            logd {
                Event(MedicineLogOperator.self, "Saved store after operation: \(didSucceed)")
            }
        }
    }
    
    private func emit() {
        DispatchQueue.main.sync { [weak self] in
            self?.objectWillChange.send()
        }
    }
    
}
