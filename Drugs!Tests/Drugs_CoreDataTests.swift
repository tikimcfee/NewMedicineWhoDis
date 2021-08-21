//
//  Drugs_Tests.swift
//  Drugs!Tests
//
//  Created by Ivan Lugo on 8/31/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import XCTest
import CoreData

class Drugs_CoreDataTests: XCTestCase {
    
    private let testQueue = DispatchQueue(label: "TestBackgroundQueue")
    
    var manager: MedicineLogCoreDataManager!
    
    override func setUpWithError() throws {
        manager = MedicineLogCoreDataManager()
        manager.createContainer()
    }
    
    override func tearDownWithError() throws {
        manager.clearFirstContainer()
    }
    
    func test_CoreDataBasicSave() {
        let expectation = expectation(description: "Failed to create, updated, and save")
        manager.mirror { mirror in
            do {
                let drug = try mirror.insertNew(of: CoreDrug.self)
                drug.drugName = "This is a mirror drug"
                try mirror.save()
                expectation.fulfill()
            } catch {
                XCTFail((error as NSError).description)
                return
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
}

