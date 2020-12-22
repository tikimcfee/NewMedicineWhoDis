//
//  Drugs_Tests.swift
//  Drugs!Tests
//
//  Created by Ivan Lugo on 8/31/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import XCTest
import CoreData

class Drugs_Tests: XCTestCase {

    private let testQueue = DispatchQueue(label: "TestBackgroundQueue")

    private var medicineStore: MedicineLogFileStore!
    private var dataManager: MedicineLogDataManager!

    private var notificationState: NotificationInfoViewState!
    private var rootScreenState: RootScreenState!

    override func setUp() {
        // Remove test data
        let lock = DispatchSemaphore(value: 1)
        medicineStore.save(applicationData: ApplicationData()) { _ in lock.signal() }
        lock.wait()

        dataManager = MedicineLogDataManager(
            persistenceManager: FilePersistenceManager(store: medicineStore),
            appData: medicineStore.load().applicationData
        )
        notificationState = NotificationInfoViewState(dataManager)
        rootScreenState = RootScreenState(dataManager, NotificationScheduler(notificationState: notificationState))
    }

    override func tearDown() {
        // Remove test data
        let lock = DispatchSemaphore(value: 1)
        medicineStore.save(applicationData: ApplicationData()) { _ in lock.signal() }
        lock.wait()
    }

    func testDateFormat() {
        let formatter = DateFormatter()
        formatter.dateFormat = "eee MMM dd"
//        let date = formatter.date(from: "Thu Dec 10")
//        let string = formatter.string(from: date!)
//        let final = string
    }

    func testTakableMeds() {
        XCTAssert(
            rootScreenState.currentEntries.count == 0,
            "Must start test without any entries"
        )

        var rand: Int { Int.random(in: 0...100) }

        func makeMap() -> [Drug: Int] { [
            Drug("Drug 1", [], 6) : rand,
            Drug("Drug 2", [], 12) : rand,
            Drug("Drug 3", [Ingredient("AnIngredient")], 3) : rand,
            Drug("Drug 4", [Ingredient("AnIngredient2"),
                            Ingredient("AnIngredient3")], Double(rand)) : rand,
        ] }

        // Make test map
        let entryMap: [Drug: Int] = makeMap()

        // Set on state
        rootScreenState.drugSelectionModel.inProgressEntry.entryMap = entryMap

        // Save once
        let saveFinished = XCTestExpectation(description: "Save completes")
        testQueue.async {
            self.rootScreenState.saveNewEntry()
            sleep(2)
            saveFinished.fulfill()
        }

        wait(for: [saveFinished], timeout: 5)
        XCTAssert(
            rootScreenState.currentEntries.count == 1,
            "Entry was not saved!"
        )
        XCTAssert(
            rootScreenState.currentEntries.first!.drugsTaken == entryMap,
            "Drug map was not transferred to entry correctly"
        )

        // Save multiple times
        let allSavesFinished = XCTestExpectation(description: "All save completed")
        allSavesFinished.expectedFulfillmentCount = 10
        testQueue.async {
            for _ in 0...10 {
                let newMap = makeMap()
                self.rootScreenState.drugSelectionModel.inProgressEntry.entryMap = newMap
                self.rootScreenState.saveNewEntry()
                allSavesFinished.fulfill()
            }
        }
        wait(for: [allSavesFinished], timeout: 5)
    }

}
