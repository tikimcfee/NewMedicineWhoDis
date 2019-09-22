//
//  ApplicationState.swift
//  Drugs!
//
//  Created by Ivan Lugo on 9/8/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import Foundation

public class CoreAppState: Storable {
    
    var mainEntryList: [MedicineEntry]
    
    init(medicineMap: [MedicineEntry] = []) {
        self.mainEntryList = medicineMap
    }
    
    public func lastEntryTiming() -> [Drug: Date] {
        return mainEntryList.last?.timesDrugsAreNextAvailable ?? [:]
    }
    
    public static func == (lhs: CoreAppState, rhs: CoreAppState) -> Bool {
        return lhs.mainEntryList == rhs.mainEntryList
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(mainEntryList)
    }
}

public extension CoreAppState {
    func addEntry(medicineEntry: MedicineEntry) {
        mainEntryList.insert(medicineEntry, at: 0)
    }
    
    func removeEntry(id: String) {
        mainEntryList.removeAll {
            $0.randomId == id
        }
    }
}
