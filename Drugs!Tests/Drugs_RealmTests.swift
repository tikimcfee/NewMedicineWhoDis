//
//  Drugs_RealmTests.swift
//  Drugs!Tests
//
//  Created by Ivan Lugo on 8/21/21.
//  Copyright © 2021 Ivan Lugo. All rights reserved.
//

import XCTest

import RealmSwift
import Combine
@testable import Meds_

class Drugs_RealmTests: XCTestCase {
    
    var manager: EntryLogRealmManager!
    var defaultLogRealm: Realm!

    override func setUpWithError() throws {
        manager = TestingRealmManager()
        defaultLogRealm = try manager.loadEntryLogRealm()
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
        let (_, legacyAppData) = try addTestDataToRealm()
        
        let legacyLookup = legacyAppData.mainEntryList.reduce(
            into: [String: MedicineEntry]()
        ) { lookup, value in lookup[value.id] = value }
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
        
        let fetchedAvailable = defaultLogRealm.objects(RLM_AvailableDrugList.self)
        XCTAssert(fetchedAvailable.count == 1, "Should only ever have one of these")
        let realmList = fetchedAvailable.first!
        let realmNames = realmList.drugs.reduce(into: Set<String>()) { set, drug in
            set.insert(drug.name)
        }
        let oldDrugNames = legacyAppData.availableDrugList.drugs.reduce(into: Set<String>()) {
            $0.insert($1.drugName)
        }
        XCTAssertEqual(realmNames, oldDrugNames, "Mismatched drug names in available list")
    }
    
    func testPersistenceManagerProtocol() throws {
        try clearTestData()
        
        let realm = RealmPersistenceManager(manager: manager)
        let (files, oldData) = try addTestDataToRealm()
        
        oldData.mainEntryList.forEach { testEntry in
            let fromRealm = realm.getEntry(with: testEntry.id)
            let fromFiles = files.getEntry(with: testEntry.id)
            XCTAssertEqual(fromRealm, fromFiles, "Loaded entries do not match")
        }
    }
    
    func testCombine() throws {
        class Test {
            @Published var name: String = "initial"
        }
        
        class TestObs: ObservableObject {
            @Published var name: String = "initial-obs"
        }
        
        let notAnnotatedInitial = expectation(description: "Did not get value from non-annotated")
        notAnnotatedInitial.expectedFulfillmentCount = 2
        
        let annotatedInitial = expectation(description: "Did not get value from annotated")
        annotatedInitial.expectedFulfillmentCount = 2
        
        var bag = Set<AnyCancellable>()
        let test = Test()
        let testObs = TestObs()
        
        test.$name.sink { value in
            print(value)
            notAnnotatedInitial.fulfill()
        }.store(in: &bag)
        
        testObs.$name.sink { value in
            print(value)
            annotatedInitial.fulfill()
        }.store(in: &bag)
        
        test.name = "Second"
        testObs.name = "Second-OBS"
        
        wait(for: [notAnnotatedInitial, annotatedInitial], timeout: 1.0)
    }
    
    func addTestDataToRealm() throws -> (FilePersistenceManager, ApplicationData) {
        let files = FilePersistenceManager(store: EntryListFileStore())
        let legacyAppData = try files.loadFromFileStoreImmediately()
        
        let startCount = legacyAppData.mainEntryList.count
        XCTAssert(startCount > 0, "Legacy data did not have at least one entry")
        
        let migrator = V1Migrator()
        let newRLMList = migrator.migrateAvailableToRealmObjects(legacyAppData.availableDrugList)
        let newRLMModels = migrator.migrateEntriesToRealmObjects(legacyAppData.mainEntryList)
        XCTAssert(newRLMModels.count == legacyAppData.mainEntryList.count, "Did not end up with same entry counts")
        XCTAssert(newRLMList.drugs.count == legacyAppData.availableDrugList.drugs.count, "Did not end up with same entry counts")
        
        try defaultLogRealm.write {
            newRLMModels.forEach {
                defaultLogRealm.add($0)
            }
            defaultLogRealm.add(newRLMList)
        }
        
        return (files, legacyAppData)
    }
    
    func clearTestData() throws {
        try defaultLogRealm.write {
            defaultLogRealm.deleteAll()
        }
    }
}
