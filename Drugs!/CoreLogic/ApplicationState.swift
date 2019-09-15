//
//  ApplicationState.swift
//  Drugs!
//
//  Created by Ivan Lugo on 9/8/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import Foundation

// Read up on Class vs Struct, SwiftUI differences... 'cause the whole thing COMPILES but BREAKS if this is a class. Lol.
public class CoreAppState: Storable {
    
    var medicineMap: [MedicineEntry]
    
    init(medicineMap: [MedicineEntry] = []) {
        self.medicineMap = medicineMap
    }
    
    public func lastEntryTiming() -> [Drug: Date] {
        return self.medicineMap.last?.timesDrugsAreNextAvailable ?? [:]
    }
    
    public static func == (lhs: CoreAppState, rhs: CoreAppState) -> Bool {
        return lhs.medicineMap == rhs.medicineMap
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(medicineMap)
    }
}

public extension CoreAppState {
    func addEntry(medicineEntry: MedicineEntry) {
        medicineMap.insert(medicineEntry, at: 0)
    }
    
    func removeEntry(id: String) {
        medicineMap.removeAll {
            $0.randomId == id
        }
    }
}
