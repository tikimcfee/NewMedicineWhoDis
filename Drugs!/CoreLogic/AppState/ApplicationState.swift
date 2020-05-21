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

public struct AppState: EquatableFileStorable {

    public struct Details {
        public var selectedUuid: String? = nil
        public var selectedEntry: MedicineEntry = DefaultDrugList.shared.defaultEntry
        public var editorState: DrugEntryEditorState = DrugEntryEditorState.emptyState()
    }

    public struct MainList {
        public var editorState: DrugEntryEditorState = DrugEntryEditorState.emptyState()
    }

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

    func indexFor(_ medicineEntry: MedicineEntry) -> Int? {
        return mainEntryList.firstIndex(where: { $0.uuid == medicineEntry.uuid })
    }

    mutating func updateModelInPlace(_ medicineEntry: MedicineEntry) {
        mainEntryList[indexFor(medicineEntry)!] = medicineEntry
    }

    public static func == (lhs: AppState, rhs: AppState) -> Bool {
        return lhs.mainEntryList == rhs.mainEntryList
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(mainEntryList)
    }
}
