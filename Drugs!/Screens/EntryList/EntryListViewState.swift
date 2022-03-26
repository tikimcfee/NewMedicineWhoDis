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
    let listOfDrugs: String // entry.drugList
    let dateTaken: String //
    let entryId: String
    
    let onSelect: Action
}

class EntryListViewModel: ObservableObject {
    @Published var entryForEdit: RLM_MedicineEntry?
    
    func didSelectRow(
        _ row: EntryListViewRowModel,
        in results: Results<RLM_MedicineEntry>
    ) {
        guard let entry = results.first(where: { $0.id == row.entryId }) else {
            log { Event("Failed to retrieve entry for edit: \(row)") }
            return
        }
        entryForEdit = entry
    }
    
    func didDeleteRow(
        _ index: Int,
        in results: Results<RLM_MedicineEntry>
    ){
        guard results.indices.contains(index),
            let entry = Optional(results[index])?.thaw(), // thaw at model level to unthaw up to realm (is unmanaged otherwise)
            let realm = entry.realm
        else {
            log { Event("Failed to retrieve unthawed entry or realm for edit: \(index); \(String(describing: results.realm))") }
            return
        }
        
        do {
            try realm.write {
                realm.delete(entry)
            }
        } catch {
            log { Event("Failed to delete roealm model: \(error)", .error ) }
        }
    }
    
    func createRowModel(_ entry: RLM_MedicineEntry) -> EntryListViewRowModel {
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
            return entry.drugsTaken.sorted {
                switch($0.drug, $1.drug) {
                case let(.some(left), .some(right)): return left.name < right.name
                case (.some, .none): return true
                default: return false
                }}
            .compactMap { $0.drug?.name }
            .joined(separator: ", ")
        }
    }
}
