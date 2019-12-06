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

// Global encoders / decoder instances ... should we really?
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
    
    func save(appState: AppState) -> Bool {
        do {
            let jsonData = try jsonEncoder.encode(appState)
            try jsonData.write(to: medicineLogsDefaultFile)
            return true
        } catch {
			loge {
				Event(MedicineLogStore.self, "Encoding error : \(error)", .critical)
			}
            return false
        }
    }
    
    func load() -> AppState {
		if !fileManager.fileExists(atPath: medicineLogsDefaultFile.path) {
			logd {
				Event(MedicineLogStore.self, "No existing logs; creating new CoreAppState")
			}
			return AppState()
		}
        do {
            let stateDate = try Data.init(contentsOf: medicineLogsDefaultFile)
            return try jsonDecoder.decode(AppState.self, from: stateDate)
        } catch {
			loge {
				Event(MedicineLogStore.self, "Decoding error : \(error); returning a new CoreAppState", .critical)
			}
            return AppState()
        }
    }
}


enum LogOperation {
    case add(_ medicineEntry: MedicineEntry)
    case remove(_ medicineEntryId: String)
}

/// This whole 'LogStore' and 'Operator' thing is getting annoying.. make it better
/// - Why is there an Operator and an AppState? Is it really so important to separate the code?

public class MedicineLogOperator: ObservableObject {
    
    private let medicineStore: MedicineLogStore
    @Published private var coreAppState: AppState
	
	private let queue: DispatchQueue
    
    var currentEntries: [MedicineEntry] {
        return coreAppState.mainEntryList
    }
    
    init(
        medicineStore: MedicineLogStore,
        coreAppState: AppState,
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
		onQueue {
			.add(medicineEntry)
		}
    }
    
    func removeEntry(id: String) {
		onQueue {
			.remove(id)
		}
    }
    
	func onQueue(_ operation: @escaping () -> LogOperation) { /// Is the operation thing really necessary? I guess it let's us skip action if we want
        queue.async {
            self.emit()
			
			let op = operation()
			
            switch(op) {
				case .add(let medicineEntry):
					self.coreAppState.addEntry(medicineEntry: medicineEntry)
            
				case .remove(let medicineEntryId):
					self.coreAppState.removeEntry(id: medicineEntryId)
            }
            
            let didSucceed = self.medicineStore.save(appState: self.coreAppState)
			
			logd {
				Event(MedicineLogOperator.self, "Operation::\n\t'\(op)'\n\tSuccess:\(didSucceed)")
			}
        }
    }
    
    private func emit() {
        DispatchQueue.main.sync { [weak self] in
            self?.objectWillChange.send()
        }
    }
    
}
