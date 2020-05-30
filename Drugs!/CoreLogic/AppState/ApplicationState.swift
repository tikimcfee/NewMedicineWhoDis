//
//  ApplicationState.swift
//  Drugs!
//
//  Created by Ivan Lugo on 9/8/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import Foundation
import Combine

enum AppStateError: Error {
    case updateError
    case saveError(cause: Error)
    case removError(cause: Error)
}

extension AppStateError: Identifiable {
    var id: String {
        switch self {
        case .saveError:
            return "saveError"
        default:
            return "unknown"
        }
    }
}

// =================================

public struct Details {
    public var selectedUuid: String? = nil
    public var selectedEntry: MedicineEntry = DefaultDrugList.shared.defaultEntry
    public var editorState: DrugEntryEditorState = DrugEntryEditorState.emptyState()

    mutating func saveEdits() -> MedicineEntry {
        selectedEntry.drugsTaken = editorState.inProgressEntry.entryMap
        selectedEntry.date = editorState.inProgressEntry.date
        return selectedEntry
    }

    mutating func setSelected(_ entry: MedicineEntry) {
        editorState = DrugEntryEditorState(sourceEntry: entry)
        selectedEntry = entry
        selectedUuid = entry.uuid
    }
}

public struct MainList {
    public var editorState: DrugEntryEditorState = DrugEntryEditorState.emptyState()

    mutating func createEntryFromEditor() -> MedicineEntry {
        return MedicineEntry(Date(), editorState.inProgressEntry.entryMap)

    }
}

public struct AppState {

    public var detailState = Details()
    public var mainListState = MainList()
    public var applicationData = ApplicationData()

    init () { }

    init(_ appData: ApplicationData) {
        self.applicationData = appData
    }

    // Saved data
    public var mainEntryList: [MedicineEntry] {
        get { return applicationData.mainEntryList }
        set { applicationData.mainEntryList = newValue.sorted { $0.date > $1.date } }
    }
}

public extension AppState {
    func indexFor(_ medicineEntry: MedicineEntry) -> Int? {
        return mainEntryList.firstIndex(where: { $0.uuid == medicineEntry.uuid })
    }

    subscript(index: Int) -> MedicineEntry {
        get { return mainEntryList[index] }
        set { mainEntryList[index] = newValue }
    }
}
