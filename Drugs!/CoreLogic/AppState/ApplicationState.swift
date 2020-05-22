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
        return MedicineEntry(
            date: Date(),
            drugsTaken: editorState.inProgressEntry.entryMap
        )

    }
}

public struct AppState: EquatableFileStorable {

    public enum CodingKeys: CodingKey {
        case listState
    }

    // App state
    public var detailState = Details()
    public var mainListState = MainList()

    // Saved data
    public var mainEntryList: [MedicineEntry] = []

    public init() { }

    public init(from decoder: Decoder) throws {
        let codedKeys = try decoder.container(keyedBy: AppState.CodingKeys.self)
        self.mainEntryList = try codedKeys.decode(Array<MedicineEntry>.self, forKey: .listState)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AppState.CodingKeys.self)
        try container.encode(mainEntryList, forKey: .listState)
    }

    public static func == (lhs: AppState, rhs: AppState) -> Bool {
        return lhs.mainEntryList == rhs.mainEntryList
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(mainEntryList)
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
