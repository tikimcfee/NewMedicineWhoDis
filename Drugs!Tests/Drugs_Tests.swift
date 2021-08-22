//
//  Drugs_Tests.swift
//  Drugs!Tests
//
//  Created by Ivan Lugo on 8/31/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import XCTest
import CoreData

@testable import Meds_

class Drugs_Tests: XCTestCase {

    private let testQueue = DispatchQueue(label: "TestBackgroundQueue")

    private var medicineStore: FilePersistenceManager!
    private var dataManager: MedicineLogDataManager!

    private var notificationState: NotificationInfoViewState!
    private var rootScreenState: AddEntryViewState!

    override func setUp() {
        // Remove test data
        let lock = DispatchSemaphore(value: 1)
        medicineStore = FilePersistenceManager(store: EntryListFileStore())
        medicineStore.save() { _ in lock.signal() }
        lock.wait()

        dataManager = MedicineLogDataManager(
            persistenceManager: medicineStore
        )
        notificationState = NotificationInfoViewState(dataManager)
        rootScreenState = AddEntryViewState(dataManager, NotificationScheduler(notificationState: notificationState))
    }

    override func tearDown() {
        // Remove test data
        let lock = DispatchSemaphore(value: 1)
        medicineStore.save() { _ in lock.signal() }
        lock.wait()
    }
    
    func testAppStateCodable() {
        var appData = ApplicationData()
        appData.availableDrugList = AvailableDrugList.defaultList
        
        var entryCount = 100
        repeat {
            appData.mainEntryList.append(TestData.shared.randomEntry())
            entryCount -= 1
        } while entryCount > 0
        
        
        let testDirectory = AppFiles.directory(named: "test_data")
        let testFile = AppFiles.file(named: "test_app_data.json", in: testDirectory)
        let store = FileStore(targetFile: testFile)
        let testFileStore = EntryListFileStore(filestore: store)
        
        func waitForSave(of appData: ApplicationData) {
            let saveFinished = XCTestExpectation(description: "Save finished")
            testFileStore.save(applicationData: appData) { result in
                saveFinished.fulfill()
            }
            wait(for: [saveFinished], timeout: 3.0)
        }
        
        waitForSave(of: appData)
        var reloadedAppData = testFileStore.load().applicationData
        XCTAssertEqual(appData, reloadedAppData)
        
        appData.mainEntryList.remove(at: 0)
        reloadedAppData.mainEntryList.remove(at: 0)
        
        waitForSave(of: reloadedAppData)
        reloadedAppData = testFileStore.load().applicationData
        XCTAssertEqual(appData, reloadedAppData)
        
    }

    func testDateFormat() {
        let formatter = DateFormatter()
        formatter.dateFormat = "eee MMM dd"
        let date = formatter.date(from: "Thu Dec 10")
        let string = formatter.string(from: date!)
        print(string)
    }

    func testClockWords() {
        let dates = [
            Date() - TimeInterval(60 * 60 * 3),
            Date() - TimeInterval(60 * 60 * 2),
            Date() - TimeInterval(60 * 60),
            Date(),
            Date() + TimeInterval(60 * 20),
            Date() + TimeInterval(60 * 60),
            Date() + TimeInterval(60 * 20 * 2),
            Date() + TimeInterval(60 * 60 * 2),
            Date() + TimeInterval(60 * 20 * 4),
            Date() + TimeInterval(60 * 60 * 3),
            Date() + TimeInterval(60 * 20 * 6),
            Date() + TimeInterval(60 * 60 * 4),
            Date() + TimeInterval(60 * 20 * 8),
            Date() + TimeInterval(60 * 60 * 5),
        ]

        for date in dates {
            ClockWords.clockFor(date)
        }
    }

}
