//
//  Drugs_UITests.swift
//  Drugs!UITests
//
//  Created by Ivan Lugo on 8/31/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import XCTest

extension XCUIApplication {
    func tapBackButton() {
        navigationBars.buttons.element(boundBy: 0).tap()
    }

    func tap(_ number: NumberPad) {
        buttons[number.rawValue].tap()
    }

    func tap(_ drug: DrugList) {
        buttons[drug.rawValue].tap()
    }

    func tap(_ button: MedicineLogScreen) {
        buttons[button.rawValue].tap()
    }

    func tap(_ button: DetailScreen) {
        buttons[button.rawValue].tap()
    }

    func tap(_ button: EditEntryScreen) {
        switch button {
        case .datePickerButton:
            datePickers[button.rawValue].tap()
        case .saveEditsButton,
             .cancelEditsButton:
            buttons[button.rawValue].tap()
        case .newTimeLabel,
             .oldTimeLabel:
            staticTexts[button.rawValue].tap()
        }
    }
    
    func table(_ x: XCUIElementQuery) {
        
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
        let entryTypeOne: [(DrugList, NumberPad)] = [
            (.Dramamine, .four),
            (.Excedrin, .seven),
            (.Ibuprofen, .six)
        ]
        let testDrugs = entryTypeOne.map { $0.0 }
        make(entryTypeOne)
        checkFirstCellInTableFor(drugs: testDrugs)

        // Check same drugs are in the list
        app.launchArguments = []
        app.terminate()
        app.launch()
        checkFirstCellInTableFor(drugs: testDrugs)
    }

    func test_EditEntry() {
        app.launchArguments = [
            AppTestArguments.enableTestConfiguration.rawValue,
            AppTestArguments.clearEntriesOnLaunch.rawValue,
        ]
        app.launch()

        // Tap some medicine, then save
        let entryTypeOne: [(DrugList, NumberPad)] = [
            (.Dramamine, .four),
            (.Excedrin, .seven),
            (.Ibuprofen, .six)
        ]
        let testDrugs = entryTypeOne.map { $0.0 }
        make(entryTypeOne)

        // Test edit
        tapCellInEntryTable()
        app.tap(.datePickerButton)
        app.setupModalEditorDatePicker("Sep 15", 5, 30, "PM")
        app.tap(.saveEditsButton)

        // Check the list again
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
            let tableCellCount = app.tables[MedicineLogScreen.entryCellList.rawValue].cells.count
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

    // MARK: Home screen

    func make(_ list: [(DrugList, NumberPad)]) {
        list.forEach {
            app.tap($0.0)
            app.tap($0.1)
        }
        app.tap(.saveEntry)
    }
    
    @discardableResult
    func selectEntryList() -> XCUIElement {
        app.tabBars.buttons.element(boundBy: 1).tap()
        let table = app.tables[MedicineLogScreen.entryCellList.rawValue]
        XCTAssert(table.waitForExistence(timeout: 1), "Main list wasn't found")
        return table
    }

    func tapCellInEntryTable(_ position: Int = 0) {
        let mainTable = selectEntryList()
        mainTable.cells.element(boundBy: position).tap()

//        let entryButtons = app.buttons[MedicineLogScreen.entryCellButton.rawValue]
//        app.buttons[MedicineLogScreen.entryCellButton.rawValue].
    }

    func checkFirstCellInTableFor(drugs: [DrugList]) {
        selectEntryList()
        let entryButtons = app.buttons[MedicineLogScreen.entryCellButton.rawValue]
        let firstEntryButtonText = entryButtons.firstMatch.label.lowercased()
        let allDrugsInLabel = drugs.allSatisfy { firstEntryButtonText.contains($0.rawValue.lowercased()) }
        XCTAssert(allDrugsInLabel, "Drugs are missing from the entry.")
    }
}

extension XCUIApplication {
    var modalEditorDatePicker: XCUIElement { datePickers.firstMatch }
    var dayWheel: XCUIElement { modalEditorDatePicker.pickerWheels.element(boundBy: 0) }
    var hourWheel: XCUIElement { modalEditorDatePicker.pickerWheels.element(boundBy: 1) }
    var minuteWheel: XCUIElement { modalEditorDatePicker.pickerWheels.element(boundBy: 2) }
    var amPmWheel: XCUIElement { modalEditorDatePicker.pickerWheels.element(boundBy: 3) }
    
    func setupModalEditorDatePicker(
        _ day: String?,
        _ hour: Int?,
        _ minute: Int?,
        _ amPM: String?
    ) {
        if let day = day { dayWheel.adjust(toPickerWheelValue: day) }
        if let hour = hour { hourWheel.adjust(toPickerWheelValue: String(hour)) }
        if let minute = minute { minuteWheel.adjust(toPickerWheelValue: String(minute)) }
        if let amPM = amPM { amPmWheel.adjust(toPickerWheelValue: amPM.uppercased()) }
    }
}
