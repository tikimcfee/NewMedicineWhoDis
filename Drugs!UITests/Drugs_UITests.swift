//
//  Drugs_UITests.swift
//  Drugs!UITests
//
//  Created by Ivan Lugo on 8/31/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import XCTest

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

class Drugs_UITests: XCTestCase {

    // The app is created, not launched. Do this in each test.
    // This keeps helper functions from needing app params.
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() {

    }

    func test_CreateAndSave() {
        app.launchArguments = [
            AppTestArguments.enableTestConfiguration.rawValue,
            AppTestArguments.clearEntriesOnLaunch.rawValue,
        ]
        app.launch()

        // Tap some medicine, then save
        let testDrugs: [DrugList] = [.Dramamine, .Excedrin, .Ibuprofen]
        app.tap(.Dramamine)
        app.tap(.two)
        app.tap(.Excedrin)
        app.tap(.four)
        app.tap(.Ibuprofen)
        app.tap(.six)
        app.tap(.saveEntry)
        sleep(1)
        checkFirstCellInTableFor(drugs: testDrugs)

        // Check same drugs are in the list
        app.launchArguments = []
        app.terminate()
        app.launch()
        checkFirstCellInTableFor(drugs: testDrugs)
    }

    // So far, this test shows a lot of performance degradation in the entry list.
    // This suggests changing the UI to have the list be somewhere else, and to save
    // data differently. Perhaps, ya know... a database. =(
    // Ugh... do I really need core data? Or to stop sucking at basic file management?
    func test_DestroyTheAppWithLotsOfData() {
        app.launchArguments = [
            AppTestArguments.enableTestConfiguration.rawValue,
            AppTestArguments.clearEntriesOnLaunch.rawValue,
            AppTestArguments.disableAnimations.rawValue
        ]
        app.launch()

        // Tap some medicine, then save
        let entryTypeOne: [(DrugList, NumberPad)] = [
            (.Dramamine, .four),
            (.Excedrin, .seven),
            (.Ibuprofen, .six)
        ]
        let entryTypeTwo: [(DrugList, NumberPad)] = [
            (.Vitamins, .two),
            (.Melatonin, .eight),
            (.Venlafaxine, .one),
            (.Omeprazole, .three)
        ]

        // Fill list with entries
        let expectedCellCount = 128 // Keep even to avoid rounding
        for _ in (0..<expectedCellCount / 2) {
            make(entryTypeOne)
            make(entryTypeTwo)
        }

        func assertFirstCellAndCount() {
            checkFirstCellInTableFor(drugs: entryTypeTwo.map { $0.0 })
            let tableCellCount = app.tables[HomeButtons.entryCellList.rawValue].cells.count
            XCTAssert(
                expectedCellCount == tableCellCount,
                "Bad cell count: \(expectedCellCount) != \(tableCellCount)"
            )
        }

        // Check same drugs are in the list
        assertFirstCellAndCount()
        app.launchArguments = []
        app.terminate()
        app.launch()
        assertFirstCellAndCount()
    }

    func make(_ list: [(DrugList, NumberPad)]) {
        list.forEach {
            app.tap($0.0)
            app.tap($0.1)
        }
        app.tap(.saveEntry)
    }

    func checkFirstCellInTableFor(drugs: [DrugList]) {
        let mainTable = app.tables[HomeButtons.entryCellList.rawValue]
        XCTAssert(mainTable.exists, "Main list wasn't found")

        // TODO: Ask someone why child labels get 'swallowed up' and they can't be found.
        // This is happening with a Button that has a 'View' with two 'Text' children
        let entryButtons = app.buttons[HomeButtons.entryCellButton.rawValue]
        let firstEntryButtonText = entryButtons.firstMatch.label.lowercased()
        let allDrugsInLabel = drugs.allSatisfy { firstEntryButtonText.contains($0.rawValue.lowercased()) }
        XCTAssert(allDrugsInLabel, "Drugs are missing from the entry.")
    }
}




