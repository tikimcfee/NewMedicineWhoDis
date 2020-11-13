//
//  Drugs_UITests.swift
//  Drugs!UITests
//
//  Created by Ivan Lugo on 8/31/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import XCTest

class Drugs_UITests: XCTestCase {

    override func setUp() {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
    }

    override func tearDown() {

    }

//    func testRootScreen() {
//        let app = XCUIApplication()
//        app.launch()
//
//        NumberPad.allCases.forEach { number in
//            XCTAssert(app.buttons[number.rawValue].exists, "Number pad is broken: \(number)")
//        }
//    }

    func testCreateAndSave() {
        let app = XCUIApplication()

        func assertTableData() {
            let mainTable = app.tables[HomeButtons.entryCellList.rawValue]
            XCTAssert(mainTable.exists, "Main list wasn't found")

            // TODO: Ask someone why child labels get 'swallowed up' and they can't be found.
            // This is happening with a Button that has a 'View' with two 'Text' children
            let entryButtons = app.buttons[HomeButtons.entryCellButton.rawValue]
            let firstButton = entryButtons.firstMatch.label.lowercased()
            let containsDrugs =
                firstButton.contains(DrugList.Dramamine.rawValue.lowercased())
                && firstButton.contains(DrugList.Excedrin.rawValue.lowercased())
                && firstButton.contains(DrugList.Ibuprofen.rawValue.lowercased())
            XCTAssert(containsDrugs, "Drugs are missing from the entry.")
        }

        // Set first app launch options
        app.launchArguments = [
            AppTestArguments.enableTestConfiguration.rawValue,
            AppTestArguments.clearEntriesOnLaunch.rawValue,
        ]
        app.launch()

        // Tap some medicine, then save
        app.tap(.Dramamine)
        app.tap(.two)
        app.tap(.Excedrin)
        app.tap(.four)
        app.tap(.Ibuprofen)
        app.tap(.six)
        app.tap(.saveEntry)
        sleep(1)
        assertTableData()

        // Clear launch args, terminate, and restart
        app.launchArguments = []
        app.terminate()
        app.launch()
        assertTableData()
    }
}

extension XCUIApplication {
    func tap(_ number: NumberPad) {
        buttons[number.rawValue].tap()
    }

    func tap(_ drug: DrugList) {
        buttons[drug.rawValue].tap()
    }

    func tap(_ button: HomeButtons) {
        buttons[button.rawValue].tap()
    }
}


