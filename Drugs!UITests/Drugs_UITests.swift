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
        case .saveEditsButton:
            buttons[button.rawValue].tap()
        case .newTimeLabel,
             .oldTimeLabel:
            staticTexts[button.rawValue].tap()
        }
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
        app.tap(.editThisEntry)
        app.tap(.datePickerButton)
        setEditEntryDatePickerTime(dayDelta: 0, hourDelta: -4, minuteDelta: 0)
        app.tap(.saveEditsButton)

        // Check the list again
        app.tapBackButton()
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

    func tapCellInEntryTable(_ position: Int = 0) {
        let mainTable = app.tables[MedicineLogScreen.entryCellList.rawValue]
        XCTAssert(mainTable.exists, "Main list wasn't found")
        mainTable.cells.element(boundBy: position).tap()

//        let entryButtons = app.buttons[MedicineLogScreen.entryCellButton.rawValue]
//        app.buttons[MedicineLogScreen.entryCellButton.rawValue].
    }

    func checkFirstCellInTableFor(drugs: [DrugList]) {
        let mainTable = app.tables[MedicineLogScreen.entryCellList.rawValue]
        XCTAssert(mainTable.exists, "Main list wasn't found")

        // TODO: Ask someone why child labels get 'swallowed up' and they can't be found.
        // This is happening with a Button that has a 'View' with two 'Text' children
        let entryButtons = app.buttons[MedicineLogScreen.entryCellButton.rawValue]
        let firstEntryButtonText = entryButtons.firstMatch.label.lowercased()
        let allDrugsInLabel = drugs.allSatisfy { firstEntryButtonText.contains($0.rawValue.lowercased()) }
        XCTAssert(allDrugsInLabel, "Drugs are missing from the entry.")
    }

    // MARK: Edit screen date picker

    // This whole thing is amazingly fragile <3
    func setEditEntryDatePickerTime(dayDelta: Double, hourDelta: Double, minuteDelta: Double) {
        let minuteInSeconds = 60.0
        let hourInSeconds = minuteInSeconds * 60.0
        let dayInSeconds = hourInSeconds * 24.0

//            let oldTimeLabel = app.staticTexts[EditEntryScreen.oldTimeLabel.rawValue].label
//            let oldParsedDate = dateTimeFormatter.date(from: oldTimeLabel)!
        let newTimeLabel = app.staticTexts[EditEntryScreen.newTimeLabel.rawValue].label
        let datePicker = app.datePickers[EditEntryScreen.datePickerButton.rawValue]
        let newParsedDate = dateTimeFormatter.date(from: newTimeLabel)!

        // Thu Dec 10 9 o' clock PM
        // eee MMM dd hh 'o''clock' a
        // This is a lame guess from checking debug values in the picker.
        // It expects the below format.. perhaps it's the short format? Can test later.
        // THIS IS HORRIBLE!
        let pickerFormatter = DateFormatter()
        pickerFormatter.dateFormat = "MMM d"

        // Advance and get day + month (Nov 25 / Oct 1)
        let advancedInterval = dayDelta * dayInSeconds
            + hourDelta * hourInSeconds
            + minuteDelta * minuteInSeconds
        let newDate = newParsedDate.advanced(by: advancedInterval)
        let newDayMonthString = pickerFormatter.string(from: newDate)

        // Get hour component; fixup to clock time
        var newHourComponent = Calendar.current.component(.hour, from: newDate)
        newHourComponent = newHourComponent == 0 ? 12 // 00:15 is 12:15am; 01:15 is 01:15am
            : newHourComponent <= 12 ? newHourComponent
            : newHourComponent - 12
        let newHourString = String(newHourComponent)

        // Get minute component
        let newMinuteComponent = Calendar.current.component(.minute, from: newDate)
        let newMinuteString = newMinuteComponent < 10 ? "0\(newMinuteComponent)" : String(newMinuteComponent)

        // These bindings work on iOS 14 with WheelDatePickerStyle
        let dayMonthWheel = datePicker.pickerWheels.element(boundBy: 0)
        let hourWheel = datePicker.pickerWheels.element(boundBy: 1)
        let minuteWheel = datePicker.pickerWheels.element(boundBy: 2)

        dayMonthWheel.adjust(toPickerWheelValue: newDayMonthString)
        hourWheel.adjust(toPickerWheelValue: newHourString)
        minuteWheel.adjust(toPickerWheelValue: newMinuteString)
    }
}




