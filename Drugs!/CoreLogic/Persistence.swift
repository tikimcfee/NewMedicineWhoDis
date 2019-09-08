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

private let jsonEncoder = JSONEncoder()
private let jsonDecoder = JSONDecoder()
private let fileManager = FileManager.default

private var documentsDirectory: URL {
    let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

public class MedicineLogStore {
    
    private var medicineLogsDirectory: URL {
        let logsDirUrl = documentsDirectory.appendingPathComponent("medicineLogs", isDirectory: true)
        if !fileManager.fileExists(atPath: logsDirUrl.path) {
            try! fileManager.createDirectory(at: logsDirUrl, withIntermediateDirectories: true, attributes: nil)
        }
        return logsDirUrl
    }
    
    private var medicineLogsDefaultFile: URL {
        let logFileUrl = medicineLogsDirectory.appendingPathComponent("core_logs_file.json")
        if !fileManager.fileExists(atPath: logFileUrl.path) {
            fileManager.createFile(atPath: logFileUrl.path, contents: Data(), attributes: nil)
        }
        return logFileUrl
    }
    
    func save(appState: CoreAppState) -> Bool {
        do {
            let jsonData = try jsonEncoder.encode(appState)
            try jsonData.write(to: medicineLogsDefaultFile)
            return true
        } catch {
            print("Encoding error : \(error)")
            return false
        }
    }
    
    func load() -> CoreAppState? {
        do {
            let stateDate = try Data.init(contentsOf: medicineLogsDefaultFile)
            return try jsonDecoder.decode(CoreAppState.self, from: stateDate)
        } catch {
            print("Encoding error : \(error)")
            return nil
        }
    }
    
}

enum LogOperation {
    case add(_ medicineEntry: MedicineEntry)
    case remove(_ medicineEntryId: String)
}

public class MedicineLogOperator: ObservableObject {
    
    @Published private var coreAppState: CoreAppState
    
    private let medicineStore: MedicineLogStore
    private let queue: DispatchQueue
    
    var currentEntries: [MedicineEntry] {
        return coreAppState.medicineMap
    }
    
    init(
        medicineStore: MedicineLogStore,
        coreAppState: CoreAppState,
        _ queue: DispatchQueue = DispatchQueue.init(
            label: "MedicineLogOperator-Queue",
            qos: .userInteractive
        )
    ) {
        self.medicineStore = medicineStore
        self.coreAppState = coreAppState
        self.queue = queue
    }
    
    func addEntry(medicineEntry: MedicineEntry) {
        onQueue(run: .add(medicineEntry))
    }
    
    func removeEntry(id: String) {
        onQueue(run: .remove(id))
    }
    
    private func onQueue(run operation: LogOperation) {
        self.queue.async {
            
            switch(operation) {
            
            case .add(let medicineEntry):
                self.coreAppState.addEntry(medicineEntry: medicineEntry)
            
            case .remove(let medicineEntryId):
                self.coreAppState.removeEntry(id: medicineEntryId)
            }
            
            let didSucceed = self.medicineStore.save(appState: self.coreAppState)
            print("Operation::\n\t'\(operation)'\n\tSucceeded:\(didSucceed)")
            self.emit()
        }
    }
    
    private func emit() {
        DispatchQueue.main.sync { [weak self] in
            self?.objectWillChange.send()
        }
    }
    
}
