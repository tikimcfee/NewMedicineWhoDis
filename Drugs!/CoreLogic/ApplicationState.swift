//
//  ApplicationState.swift
//  Drugs!
//
//  Created by Ivan Lugo on 9/8/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import Foundation

public class AppState: Storable {
    
    private(set) var mainEntryList: [MedicineEntry]
    
    init(medicineMap: [MedicineEntry] = []) {
        self.mainEntryList = medicineMap
    }
    
    public static func == (lhs: AppState, rhs: AppState) -> Bool {
        return lhs.mainEntryList == rhs.mainEntryList
    }
    
    public func hash(into hasher: inout Hasher) {
		hasher.combine(mainEntryList)
    }
}

extension AppState {
    func addEntry(medicineEntry: MedicineEntry) {
        mainEntryList.insert(medicineEntry, at: 0)
    }
    
    func removeEntry(id: String) {
        mainEntryList.removeAll { $0.uuid == id }
    }
}
