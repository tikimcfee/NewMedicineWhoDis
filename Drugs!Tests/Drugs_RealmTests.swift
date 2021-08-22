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
        try clearTestData()
    }

    func testExample() throws {
        try clearTestData()
        
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
    
    func testMigration() throws {
        try clearTestData()
        
        let legacyFileManager = EntryListFileStore()
        let legacyAppData = try legacyFileManager.load().get()
        
        let startCount = legacyAppData.mainEntryList.count
        XCTAssert(startCount > 0, "Legacy data did not have at least one entry")
        let legacyLookup = legacyAppData.mainEntryList
            .reduce(into: [String: MedicineEntry]()) { lookup, value in
                lookup[value.id] = value
            }
        
        let migrator = V1Migrator()
        let newRLMModels = migrator.migrateToRealmObjects(legacyAppData.mainEntryList)
        XCTAssert(newRLMModels.count == legacyAppData.mainEntryList.count, "Did not end up with same entry counts")

        try defaultLogRealm.write {
            newRLMModels.forEach {
                defaultLogRealm.add($0)
            }
        }
        
        let fetchedObjects = defaultLogRealm.objects(RLM_MedicineEntry.self)
        try fetchedObjects.enumerated().forEach { index, object in
            let matchingLegacy = try XCTUnwrap(legacyLookup[object.id], "Did not find a matching entry")
            XCTAssertEqual(matchingLegacy.date, object.date, "Dates were not migrated correctly")
            
            let oldNames = matchingLegacy.drugsTaken.reduce(into: Set<String>()) { acc, tuple in
                acc.insert(tuple.key.id)
            }
            let drugNames = object.drugsTaken.reduce(into: Set<String>()) { acc, tuple in
                acc.insert(tuple.drug?.name)
            }
            XCTAssertEqual(oldNames, drugNames, "Mismatched drug names")
        }
    }
    
    func clearTestData() throws {
        try defaultLogRealm.write {
            defaultLogRealm.deleteAll()
        }
    }
}

//MARK: Migration extensions

public class V1Migrator {
    private var cachedMigratedDrugNames: [String: RLM_Drug] = [:]
    private var cachedMigratedIngredientNames: [String: RLM_Ingredient] = [:]
    
    public func migrateToRealmObjects(_ oldList: [MedicineEntry]) -> [RLM_MedicineEntry] {
        return oldList.map(fromV1Entry)
    }
    
    private func fromV1Entry(_ entry: MedicineEntry) -> RLM_MedicineEntry {
        let newEntry = RLM_MedicineEntry()
        newEntry.id = entry.id
        newEntry.date = entry.date
        newEntry.drugsTaken = fromV1DrugMap(entry.drugsTaken)
        return newEntry
    }
    
    private func fromV1Selection(_ drug: Drug, _ count: Double) -> RLM_DrugSelection {
        let newSelection = RLM_DrugSelection()
        newSelection.count = count
        newSelection.drug = fromV1drug(drug)
        return newSelection
    }
    
    private func fromV1drug(_ drug: Drug) -> RLM_Drug {
        if let cached = cachedMigratedDrugNames[drug.id] { return cached }
        let newDrug = RLM_Drug()
        newDrug.name = drug.drugName
        newDrug.hourlyDoseTime = drug.hourlyDoseTime
        newDrug.ingredients.append(
            objectsIn: drug.ingredients.map(fromV1Ingredient)
        )
        cachedMigratedDrugNames[drug.id] = newDrug
        return newDrug
    }
    
    private func fromV1DrugMap(_ drugMap: DrugCountMap) -> List<RLM_DrugSelection> {
        drugMap.reduce(into: List()) { list, element in
            list.append(fromV1Selection(element.key, element.value))
        }
    }
    
    private func fromV1Ingredient(_ ingredient: Ingredient) -> RLM_Ingredient {
        if let cached = cachedMigratedIngredientNames[ingredient.ingredientName] { return cached }
        
        let newIngredient = RLM_Ingredient()
        newIngredient.ingredientName = ingredient.ingredientName
        
        cachedMigratedIngredientNames[ingredient.ingredientName] = newIngredient
        return newIngredient
    }
}

//MARK: - Realm Models

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
    @Persisted(primaryKey: true) public var id: String = UUID().uuidString
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

//MARK: - Realm Helper

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
