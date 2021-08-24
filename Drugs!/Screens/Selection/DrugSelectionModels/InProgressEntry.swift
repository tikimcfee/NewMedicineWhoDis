//
//  InProgressEntry.swift
//  Drugs!
//
//  Created by Ivan Lugo on 8/23/21.
//  Copyright © 2021 Ivan Lugo. All rights reserved.
//

import Foundation

typealias InProgressDrugCountMap = [SelectableDrug: Double]

struct InProgressEntry {
    var entryMap: InProgressDrugCountMap
    var date: Date
    init(
        _ map: InProgressDrugCountMap = [:],
        _ date: Date = Date()
    ) {
        self.entryMap = map
        self.date = date
    }
}

enum InProgressEntryError: Error {
    case mappingBackToDrugs
}

extension InProgressEntry {
//    func drugMap(in availableDrugList: [AvailableDrugList]) throws -> DrugCountMap {
//        // Map view 'SelectableDrug' to data 'Drug' type
//        let drugIdMap = availableDrugList.drugs.reduce(into: [DrugId: Drug]()) { result, drug in
//            result[drug.id] = drug
//        }
//        
//        let drugMap = try entryMap.reduce(into: DrugCountMap()) { result, pair in
//            guard let drug = drugIdMap[pair.key.drugId] else {
//                throw InProgressEntryError.mappingBackToDrugs
//            }
//            result[drug] = pair.value
//        }
//        
//        return drugMap
//    }
    
    static func != (_ inProgress: InProgressEntry, _ other: MedicineEntry) -> Bool {
        return !(inProgress == other)
    }
    
    static func == (_ inProgress: InProgressEntry, _ other: MedicineEntry) -> Bool {
        guard inProgress.date == other.date else { return false }
        
        // Add each set of drugs to a map and check that the ID and count exists in the other.
        // This is weak guarantee and a little non performant.
        struct Comparison: Equatable { let name: String; let count: Double }
        
        let inProgressTuples = inProgress.entryMap
            .sorted(by: { l, r in l.key.drugName < r.key.drugName })
            .map { Comparison(name: $0.key.drugName, count: $0.value) }
        
        let entryTuples = other.drugsTaken
            .sorted(by: { l, r in l.key.drugName < r.key.drugName })
            .map { Comparison(name: $0.key.drugName, count: $0.value) }
        
        return inProgressTuples == entryTuples
    }
}
