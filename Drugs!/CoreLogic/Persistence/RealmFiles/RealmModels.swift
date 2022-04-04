//
//  RealmModels.swift
//  Drugs!
//
//  Created by Ivan Lugo on 8/21/21.
//  Copyright © 2021 Ivan Lugo. All rights reserved.
//

import Foundation
import RealmSwift

let CURRENT_SCHEMA_VERSION: UInt64 = 4

// MARK: -- Model Atoms

public class RLM_Ingredient: Object {
    @Persisted(primaryKey: true) public var id: String = UUID().uuidString
    @Persisted var ingredientName: String = ""
}

public class RLM_Drug: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) public var id: String = UUID().uuidString
    @Persisted public var name: String = ""
    @Persisted public var ingredients: List<RLM_Ingredient> = List()
    @Persisted public var hourlyDoseTime: Double = 0.0
}

public class RLM_DrugSelection: Object {
    @Persisted public var drug: RLM_Drug?
    @Persisted public var count: Double = 0.0
}

public class RLM_MedicineEntry: Object, ObjectKeyIdentifiable, RLM_EntryDateRepresentable {
    @Persisted(primaryKey: true) public var id: String = UUID().uuidString
    @Persisted(indexed: true) public var date: Date = Date()
    @Persisted public var drugsTaken: List<RLM_DrugSelection> = List()
    public var representableDate: Date { date }
}

public class RLM_MedicineEntryGroup: Object, ObjectKeyIdentifiable, RLM_EntryDateRepresentable {
    @Persisted(indexed: true) public var representableDate: Date = Date()
    @Persisted public var entries: List<RLM_MedicineEntry> = List()
    public var isToday: Bool { Date().allComponents.day == representableDate.allComponents.day }
}

// MARK: -- Singleton containers

public class RLM_AvailableDrugList: Object, Identifiable {
    @Persisted(primaryKey: true) public var id: String = RLM_AvailableDrugList.defaultId
    @Persisted public var drugs: List<RLM_Drug> = List()
    
    // Added: schema V.2
    @Persisted public var didSetDefaultList: Bool = false
}

public class RLM_AvailabilityInfoContainer: Object, Identifiable {
    @Persisted(primaryKey: true) public var id: String = RLM_AvailabilityInfoContainer.defaultId
    @Persisted public var timingInfo: Map<Drug.ID, RLM_AvailabilityStats>?
}

public class RLM_AvailabilityStats: Object {
    @Persisted public var drug: RLM_Drug?
    @Persisted public var when: Date = Date()

    convenience init(drug: RLM_Drug, when: Date) {
        self.init()
        self.drug = drug
        self.when = when
    }
    
    var canTakeAsOfNow: Bool { when < Date() }
}

public class RLM_AppMigrationData: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) public var id: String = defaultQueryId
    @Persisted var flatFileMigrationComplete: Bool = false
}
