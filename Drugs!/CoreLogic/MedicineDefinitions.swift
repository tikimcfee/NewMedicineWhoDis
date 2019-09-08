//
//  MedicineDefinitions.swift
//  Drugs!
//
//  Created by Ivan Lugo on 9/7/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import Foundation

// ---------------------------------------------------



public struct Drug: Storable {
    let name: String
}

public struct MedicineEntry: Storable {
    let date: Date
    let drugsTaken: [Drug]
    let randomId: String
    
    init(
        date: Date,
        drugsTaken: [Drug] = [],
        _ randomId: String = UUID.init().uuidString
    ) {
        self.date = date
        self.drugsTaken = drugsTaken
        self.randomId = randomId
    }
}

// Read up on Class vs Struct, SwiftUI differences... 'cause the whole thing COMPILES but BREAKS if this is a class. Lol.
public struct CoreAppState: Storable {
    var medicineMap: [MedicineEntry]
    
    init(medicineMap: [MedicineEntry] = []) {
        self.medicineMap = medicineMap
    }
}

extension CoreAppState {
    mutating func addEntry(medicineEntry: MedicineEntry) {
        medicineMap.insert(medicineEntry, at: 0)
    }
    
    mutating func removeEntry(id: String) {
        medicineMap.removeAll {
            $0.randomId == id
        }
    }
}

// ---------------------------------------------------
// ---------------------------------------------------
// ---------------------------------------------------

public let __testData__listOfDrugs: [Drug] = {
    var drugs: [Drug] = []
    drugs.append(Drug(name: "Tylenol"))
    drugs.append(Drug(name: "Advil"))
    drugs.append(Drug(name: "Excedrin"))
    drugs.append(Drug(name: "Weeeeeds!"))
    drugs.append(Drug(name: "Ibuprofen"))
    return drugs
}()

public let __testData__listOfDates: [Date] = {
    var dates: [Date] = []
    for _ in 0...10 {
        dates.append(Date())
    }
    return dates
}()

public let __testData__coreAppState: CoreAppState = {
    return CoreAppState(
        medicineMap: []
    )
}()
