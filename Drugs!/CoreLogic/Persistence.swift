//
//  Persistence.swift
//  Drugs!
//
//  Created by Ivan Lugo on 9/7/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import Foundation
import SwiftUI

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
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        emit()
        coreAppState.addEntry(medicineEntry: medicineEntry)
        saveAppState(handler)
    }

    func removeEntry(
        id: String,
        _ handler: @escaping (Result<Void, Error>) -> Void
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

    private func saveAppState(
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        saveQueue.async {
            self.medicineStore.save(appState: self.coreAppState) { result in
                self.notifyHandler(result, handler)
            }
        }
    }

    private func notifyHandler(
        _ result: Result<Void, Error>,
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        mainQueue.async {
            handler(result)
        }
    }
    
}
