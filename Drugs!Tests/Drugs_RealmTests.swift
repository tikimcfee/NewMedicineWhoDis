//
//  Drugs_RealmTests.swift
//  Drugs!Tests
//
//  Created by Ivan Lugo on 8/21/21.
//  Copyright © 2021 Ivan Lugo. All rights reserved.
//

import XCTest
import RealmSwift

class Drugs_RealmTests: XCTestCase {
    
    var manager: EntryLogRealmManager!
    var defaultLogRealm: Realm!

    override func setUpWithError() throws {
        manager = EntryLogRealmManager()
        defaultLogRealm = try manager.loadTestLogRealm()
    }

    override func tearDownWithError() throws {
        try defaultLogRealm.write {
            defaultLogRealm.deleteAll()
        }
    }

    func testExample() throws {
        let newDrug = RLM_Drug()
        newDrug.name = "Hello there, sir"
        newDrug.hourlyDoseTime = 6.0
        
        let someIngredients = List<RLM_Ingredient>()
        someIngredients.append(objectsIn: [
            RLM_Ingredient(value: ["ingredientName": "Frapple"]),
            RLM_Ingredient(value: ["ingredientName": "Kaplot"])
        ])
        newDrug.ingredients = someIngredients
        
        let someSelections = List<RLM_DrugSelection>()
        someSelections.append(objectsIn: [
            RLM_DrugSelection(value: ["drug": newDrug, "count": 5.0])
        ])
        let entry = RLM_MedicineEntry()
        entry.drugsTaken = someSelections
        
        // Try a write
        try defaultLogRealm.write {
            defaultLogRealm.add(entry)
        }
        
        // Try a read
        let rereadEntry = try XCTUnwrap(defaultLogRealm.object(
            ofType: RLM_MedicineEntry.self,
            forPrimaryKey: entry.id
        ), "Did not find expected entry")
        
        // Hope
        XCTAssertEqual(entry.date, rereadEntry.date)
        XCTAssertEqual(newDrug.id, entry.drugsTaken.first?.drug?.id)
        XCTAssertEqual(entry.drugsTaken.first?.count, 5.0)
    }
}

class EntryLogRealmManager {
    public func loadEntryLogRealm() throws -> Realm {
        var config = Realm.Configuration.defaultConfiguration
        config.fileURL = AppFiles.entryLogRealm
        let realm = try Realm(configuration: config)
        return realm
    }
    
    #if DEBUG
    public func loadTestLogRealm() throws -> Realm {
        var config = Realm.Configuration.defaultConfiguration
        config.deleteRealmIfMigrationNeeded = true
        config.fileURL = AppFiles.Testing__entryLogRealm
//        config.migrationBlock = { (migration: Migration, oldSchemaVersion: UInt64) in
//
//        }
        let realm = try Realm(configuration: config)
        return realm
    }
    #endif
}

public class RLM_AvailableDrugList: Object {
    @Persisted var drugs: List<RLM_Drug> = List()
}

public class RLM_Drug: Object {
    @Persisted(primaryKey: true) public var id: String = UUID().uuidString
    @Persisted public var name: String = ""
    @Persisted public var ingredients: List<RLM_Ingredient> = List()
    @Persisted public var hourlyDoseTime: Double = 0.0
}

public class RLM_Ingredient: Object {
    @Persisted var ingredientName: String = ""
}

public class RLM_DrugSelection: Object {
    @Persisted public var drug: RLM_Drug?
    @Persisted public var count: Double = 0.0
}

public class RLM_MedicineEntry: Object {
    @Persisted(primaryKey: true) public var id: String = UUID().uuidString
    @Persisted public var date: Date = Date()
    @Persisted public var drugsTaken: List<RLM_DrugSelection> = List()
}
