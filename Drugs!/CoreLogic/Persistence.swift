//
//  Persistence.swift
//  Drugs!
//
//  Created by Ivan Lugo on 9/7/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import Foundation

public typealias Storable = Equatable & Hashable & Codable

private var documentsDirectory: URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

private let jsonEncoder = JSONEncoder()
private let jsonDecoder = JSONDecoder()

class MedicineLogStore {
    
    private var medicineLogsDirectory: URL {
        return documentsDirectory.appendingPathComponent("medicineLogs", isDirectory: true)
    }
    
    private var medicineLogsDefaultFile: URL {
        return medicineLogsDirectory.appendingPathComponent("core_logs_file.json")
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

class MedicineLogOperator {
    
}
