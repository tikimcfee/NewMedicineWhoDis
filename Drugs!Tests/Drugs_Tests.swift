//
//  Drugs_Tests.swift
//  Drugs!Tests
//
//  Created by Ivan Lugo on 8/31/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import XCTest

class Drugs_Tests: XCTestCase {

    override func setUp() {

    }

    override func tearDown() {

    }

    func testTakableMeds() {
        let testEntries = DefaultDrugList.shared.randomEntries
        let info = testEntries.availabilityInfo()
        print(info)
    }

}
