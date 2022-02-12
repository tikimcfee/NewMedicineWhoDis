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
    
	// - Flat file
	var flatFileStore: EntryListFileStore!
	var flatFilePersistenceManager: FilePersistenceManager!
	
	// - Realm
	var appLogManager: AppEventLogRealmManager!
    var entryLogRealmManager: EntryLogRealmManager!
	
	var tokens: [NotificationToken]!
	
	// - Migration
	let migrator = V1Migrator()

    override func setUpWithError() throws {
		tokens = []
		
		flatFileStore = EntryListFileStore()
		flatFilePersistenceManager = FilePersistenceManager(store: flatFileStore)
        
		appLogManager = DefaultAppEventRealmManager.shared
        entryLogRealmManager = TestingRealmManager()
    }

    override func tearDownWithError() throws {
		tokens.forEach { $0.invalidate() }
		tokens = []
		try clearDefaultRealmData()
    }
    
    func test__FillFlatFiles() throws {
        try addTestDataToFlatFileManager()
    }

    func testExample() throws {
        try clearDefaultRealmData()
        
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
        entryLogRealmManager.access { realm in
			try realm.write {
				realm.add(entry)	
			}
        }
        
        // Try a read
		entryLogRealmManager.access { realm in
			let rereadEntry = try XCTUnwrap(realm.object(
				ofType: RLM_MedicineEntry.self,
				forPrimaryKey: entry.id
			), "Did not find expected entry")
			
			// Hope
			XCTAssertEqual(entry.date, rereadEntry.date)
			XCTAssertEqual(newDrug.id, entry.drugsTaken.first?.drug?.id)
			XCTAssertEqual(entry.drugsTaken.first?.count, 5.0)
		}
    }
    
    func testV1MigratorChecks() throws {
        flatFilePersistenceManager.removeAllData()
        try addTestDataToFlatFileManager(100)
        try clearDefaultRealmData()
        
        entryLogRealmManager.access { realm in
            try migrator.migrate(manager: flatFilePersistenceManager, into: realm)
            try migrator.migrate(manager: flatFilePersistenceManager, into: realm)
            try migrator.migrate(manager: flatFilePersistenceManager, into: realm)
        }
    }
    
    func testV1Migrator() throws {
        flatFilePersistenceManager.removeAllData()
        try addTestDataToFlatFileManager()
        try clearDefaultRealmData()
        
        entryLogRealmManager.access { realm in
            try migrator.migrate(manager: flatFilePersistenceManager, into: realm)
        }
        
        // Create persistence manager after so the initial load can be taken care of by the
        // observation. We'll still have to wait.
        let realmPersistence = RealmPersistenceManager(manager: entryLogRealmManager)
        let loadExpectation = expectation(description: "Initial data must load implicitly via observation")
        loadExpectation.assertForOverFulfill = false
        var streamData: ApplicationData?
        var dispose = Set<AnyCancellable>()
        realmPersistence.appDataStream
            .receive(on: RunLoop.main)
            .sink(receiveValue: { loaded in
                print("Sink received value...")
                streamData = loaded
                guard !loaded.mainEntryList.isEmpty,
                      !loaded.availableDrugList.drugs.isEmpty else {
                    print("Empty entry list in receive")
                    return
                }
                loadExpectation.fulfill()
            } )
            .store(in: &dispose)
        wait(for: [loadExpectation], timeout: 10.0)
        
        let loadedData = try XCTUnwrap(streamData, "Stream completed but data is nil... I don't even Swift folks")
        let persistenceData = realmPersistence.__internalAppData()
        var originalFlatData = flatFilePersistenceManager.getAppData()
        originalFlatData.mainEntryList = originalFlatData.mainEntryList.sorted(by: { $0.date > $1.date} )
        
        XCTAssertEqual(loadedData, persistenceData)
        XCTAssertEqual(persistenceData, originalFlatData, "End migrated state must match original data")
    }
    
    func testMigration() throws {
        try clearDefaultRealmData()
        let legacyAppData = try addTestDataToRealm()
        
        let legacyLookup = legacyAppData.mainEntryList.reduce(
            into: [String: MedicineEntry]()
        ) { lookup, value in lookup[value.id] = value }
		
		let fetchedObjects = try XCTUnwrap(
			entryLogRealmManager.accessImmediate { $0.objects(RLM_MedicineEntry.self) },
			"Failed to fetch entry list"
		)
		
        try fetchedObjects.enumerated().forEach { index, object in
            let matchingLegacy = try XCTUnwrap(legacyLookup[object.id], "Did not find a matching entry")
            XCTAssertEqual(matchingLegacy.date, object.date, "Dates were not migrated correctly")
            
            let oldNames = matchingLegacy.drugsTaken.reduce(into: Set<String>()) { acc, tuple in
                acc.insert(tuple.key.drugName)
            }
            let drugNames = object.drugsTaken.reduce(into: Set<String>()) { acc, tuple in
                acc.insert(tuple.drug?.name)
            }
            XCTAssertEqual(oldNames, drugNames, "Mismatched drug names")
        }
        
		let fetchedAvailable = try XCTUnwrap(
			entryLogRealmManager.accessImmediate { $0.objects(RLM_AvailableDrugList.self) },
			"Failed to drug list"
		)
		
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
        try clearDefaultRealmData()
        
        let realm = RealmPersistenceManager(manager: entryLogRealmManager)
        let oldData = try addTestDataToRealm()
        
        oldData.mainEntryList.forEach { testEntry in
            let fromRealm = realm.getEntry(with: testEntry.id)
            let fromFiles = flatFilePersistenceManager.getEntry(with: testEntry.id)
            XCTAssertEqual(fromRealm, fromFiles, "Loaded entries do not match")
        }
    }
	
	func testUpdates() throws {
		try clearDefaultRealmData()
		
		var fetchListAsSingle: RLM_AvailableDrugList? {
			entryLogRealmManager.accessImmediate { RLM_AvailableDrugList.defaultFrom($0) }
		}
		
		if fetchListAsSingle == nil {
			let newList = RLM_AvailableDrugList.makeFrom(AvailableDrugList.defaultList)
			entryLogRealmManager.access { realm in
				try realm.write {
					realm.add(newList)
				}
			}
		}
		
		let existingDefault = try XCTUnwrap(fetchListAsSingle, "Insertion / query did not succeed")
		let secondToLastItem = existingDefault.drugs[existingDefault.drugs.count - 2]
		
		let expectedNotifications = expectation(description: "Observations on DrugList failed")
		expectedNotifications.expectedFulfillmentCount = 2
		let token = entryLogRealmManager
			.accessImmediate { realm in 
				RLM_AvailableDrugList.defaultListFrom(realm)
			}!
			.observe { change in 
				switch change {
					case let .initial(results):
						XCTAssertEqual(results.first!, fetchListAsSingle)
						expectedNotifications.fulfill()
						
					case let .error(error):
						XCTFail(error.localizedDescription)
						
					case let .update(results, deletions, insertions, modifications):
						XCTAssert(deletions.isEmpty, "Unexpected deletions")
						XCTAssert(insertions.isEmpty, "Unexpected insertions")
						XCTAssert(modifications.count == 1, "Single modification not received")
						let updatedList = results[modifications[0]]
						XCTAssertEqual(secondToLastItem, updatedList.drugs.last)
						expectedNotifications.fulfill()
				}
			}
		tokens.append(token)
		entryLogRealmManager.access { realm in 
			try realm.write {
				existingDefault.drugs.removeLast()
			}
		}
		wait(for: [expectedNotifications], timeout: 1.0)
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
	
	func testLogs() throws {
		try clearDefaultRealmData()
		
		let toCreateCount = 1000
		for count in 0..<toCreateCount {
			log { Event("Testing global logs \(count)", Bool.random() ? .info : .error) }
		}
        let expect = expectation(description: "Finished load")
        DispatchQueue.main.async {
            RealmAppEventLogger.shared.manager.withRealm { realm in
                let allEvents = realm.objects(PersistableEvent.self)
                XCTAssertEqual(allEvents.count, toCreateCount)
                expect.fulfill()
            }
        }
        wait(for: [expect], timeout: 3.0)
	}
    
    func testRealmSorting() throws {
        try clearDefaultRealmData()
        let testData = try addTestDataToRealm()
        
        let sortFunction = FilePersistenceManager.defaultSortFunction
        let expectedSortedEntries = testData.mainEntryList.sorted(by: sortFunction)
        
        // Pull the realm out of closure to guarantee the XCT assertion is hit
        var realm: Realm?
        entryLogRealmManager.access { realm = $0 }
        
        let entries = try XCTUnwrap(realm).objects(RLM_MedicineEntry.self)
        let sorted = entries.sorted(by: \.date, ascending: false)
        
        XCTAssertEqual(
            sorted.map { migrator.toV1Entry($0) },
            expectedSortedEntries,
            "Entries do not match"
        )
    }
}

extension Drugs_RealmTests {
    func addTestDataToFlatFileManager(_ count: Int = 1000) throws {
        _ = try flatFilePersistenceManager.loadFromFileStoreImmediately()
        guard flatFilePersistenceManager.getAppData().mainEntryList.isEmpty else {
            print("Entry list already contains test data")
            return
        }
        
        let testData = TestData.shared
        let entriesToCreate = count
        let testEntries = (0..<entriesToCreate).map { entryIndex in
            testData.randomEntry()
        }
        
        let allAdded = expectation(description: "All entries must save corectly")
        allAdded.expectedFulfillmentCount = entriesToCreate
        
        var failedAdditions = [MedicineEntry]()
        testEntries.forEach { entry in
            flatFilePersistenceManager.addEntry(medicineEntry: entry) { result in
                switch result {
                case .success:
                    allAdded.fulfill()
                case .failure(let error):
                    print("Failed to save entry:\n||||||\(entry)||||||\(error)||||||")
                    failedAdditions.append(entry)
                }
            }
        }
        
        wait(for: [allAdded], timeout: 5.0)
    }
    
    func addTestDataToRealm() throws -> ApplicationData {
        try addTestDataToFlatFileManager()
        let legacyAppData = try flatFilePersistenceManager.loadFromFileStoreImmediately()
        let startCount = legacyAppData.mainEntryList.count
        XCTAssert(startCount > 0, "Legacy data did not have at least one entry")
        
        let newRLMList = migrator.migrateAvailableToRealmObjects(legacyAppData.availableDrugList)
        let newRLMModels = migrator.migrateEntriesToRealmObjects(legacyAppData.mainEntryList)
        XCTAssertEqual(newRLMModels.count, legacyAppData.mainEntryList.count, "Did not end up with same entry counts")
        XCTAssertEqual(newRLMList.drugs.count, legacyAppData.availableDrugList.drugs.count, "Did not end up with same entry counts")
        
        entryLogRealmManager.access { realm in
            try realm.write {
                newRLMModels.forEach { realm.add($0) }
                realm.add(newRLMList)
            }
        }
        return legacyAppData
    }
    
    func clearDefaultRealmData() throws {
        entryLogRealmManager.access { realm in
            try realm.write {
                realm.deleteAll()
            }
        }
        appLogManager.withRealm { realm in
            try realm.write {
                realm.deleteAll()
            }
        }
    }
}
