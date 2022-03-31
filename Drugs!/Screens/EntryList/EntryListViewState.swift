//
//  EntryListViewState.swift
//  Drugs!
//
//  Created by Ivan Lugo on 3/25/22.
//  Copyright © 2022 Ivan Lugo. All rights reserved.
//

import Foundation
import Combine
import RealmSwift

struct EntryListViewRowModel {
    let listOfDrugs: String
    let dateTaken: String
    let entryId: String
    
    let onSelect: Action
}

enum EntryListError: Error {
    case missingResultForUndo
}

class EntryListViewModel: ObservableObject {
    @Published var entryForEdit: Entry?
    private let undoManager = UndoManager()

    func undo() {
        undoManager.undo()
    }
    
    func delete(_ set: IndexSet, from results: ObservedResults<Entry>) {
        log("Deleting \(set)")
        
        undoManager.beginUndoGrouping()
        let undoRemovals = set.compactMap { index -> Entry? in
            guard results.wrappedValue.indices.contains(index) else {
                log(EntryListError.missingResultForUndo)
                return nil
            }
            return results.wrappedValue[index]
        }
        undoManager.registerUndo(withTarget: self) { [realm = results.wrappedValue.realm] _ in
            guard let realm = realm else {
                log("No realm for undo, sorry there friend.")
                return
            }
            do {
                try realm.write {
                    undoRemovals.forEach { realm.add($0, update: .all) }
                }
            } catch {
                log(error, "Failed to undo delete")
            }
        }
        undoManager.endUndoGrouping()
        
        results.remove(atOffsets: set)
    }
    
    func didSelectRow(_ entry: Entry) {
        log("Starting edit for \(entry.id)")
        entryForEdit = entry
    }

    func createRowModel(_ entry: Entry) -> EntryListViewRowModel {
        EntryListViewRowModel(
            listOfDrugs: makeDrugList(entry),
            dateTaken: DateFormatting.LongDateShortTime.string(from: entry.date),
            entryId: entry.id,
            onSelect: { self.entryForEdit = entry }
        )
    }
    
    private func makeDrugList(_ entry: RLM_MedicineEntry) -> String {
        if entry.drugsTaken.count == 0 {
            return "(Nothing taken)"
        } else {
            return entry.drugsTaken.lazy
                .compactMap { $0.drug?.name }
                .sorted(by: <)
                .joined(separator: ", ")
        }
    }
}
