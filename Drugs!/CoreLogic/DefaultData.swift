//
//  MedicineDefinitions__TestData.swift
//  Drugs!
//
//  Created by Ivan Lugo on 12/5/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import Foundation
import SwiftUI

public class WrappedObservable<Value>: ObservableObject {
    @Published var value: Value
    init(_ start: Value) {
        self.value = start
    }
}

public class WrappedBinding<Value> {
    private var current: Value
    init(_ start: Value) {
        self.current = start
    }
    lazy var binding = Binding<Value>(
        get: { return self.current },
        set: { (val: Value) in self.current = val }
    )
}

public class BoolBinding {
    private var current: Bool = false
    convenience init(_ start: Bool) {
        self.init()
        self.current = start
    }
    lazy var binding = Binding<Bool>(
        get: { () -> Bool in self.current },
        set: { (val: Bool) in self.current = val }
    )
}

public class DrugBinding {
    private var current: Drug = Drug("", [], 4)
    lazy var binding = Binding<Drug>(
        get: { () -> Drug in self.current },
        set: { (val: Drug) in self.current = val }
    )
}

public final class DefaultDrugList {

    public static let shared = DefaultDrugList()

    @State static var inProgressEntry: InProgressEntry = InProgressEntry()

    static func drugMapBinding() -> Binding<[Drug : Int]> {
        return Binding<[Drug : Int]>(
            get: { () -> [Drug : Int] in [:] },
            set: { (_ : [Drug : Int]) in }
        )
    }

    static func drugBinding() -> Binding<Drug?> {
        return Binding<Drug?>(
            get: { () -> Drug? in Drug("", [], 4) },
            set: { (Drug) in }
        )
    }

    private init() { }

    func randomEntry() -> MedicineEntry {
        let start = Int.random(in: 0..<drugs.count)
        let end = Int.random(in: start..<drugs.count)
        let time = -Int.random(in: 0...12)
        let minutes = -Int.random(in: 0...60)
        let date = Calendar.current.date(
            byAdding: .hour, value: time, to: Date()
        )!.addingTimeInterval(TimeInterval(minutes))
        return MedicineEntry(date,
            Array(drugs[start...end]).reduce(into: [Drug: Int]()) { result, drug in
                result[drug, default: 0] += Int.random(in: 1...4)
            }
        )
    }

    lazy var randomEntries: [MedicineEntry] = {
        return [randomEntry(), randomEntry(), randomEntry(), randomEntry()]
    }()

    lazy var defaultEntry : MedicineEntry = {
        return MedicineEntry(
            Calendar.current.date(byAdding: .hour, value: -12, to: Date())!,
            Array(drugs[0...4]).reduce(into: [Drug: Int]()) { result, drug in
                result[drug, default: 0] += Int.random(in: 1...4)
            }
        )
    }()

    lazy var drugs: [Drug] = {
        let list = [
            Drug("Gabapentin",  [Ingredient("Gabapentin")],     12),
            Drug("Tylenol",     [Ingredient("Acetaminophen")],  5),
            Drug("Venlafaxine", [Ingredient("Venlafaxine")],    24),
            Drug("Dramamine",   [Ingredient("Dimenhydrinate"),], 24),
            Drug("Excedrin",    [Ingredient("Acetaminophen"),
                                 Ingredient("Aspirin"),
                                 Ingredient("Caffeine")],       5),
            Drug("Ibuprofen",   [Ingredient("Ibuprofen")],      8),
            Drug("Omeprazole",  [Ingredient("Omeprazole")],     12),
            Drug("Melatonin",   [Ingredient("Melatonin")],      24),
            Drug("Tums",        [Ingredient("Sodium Bicarbonate")], 4),
            Drug("Vitamins",    [Ingredient("Vitamins")],       0),
        ]
        return list.sorted()
    }()

}

public func makeTestMedicineOperator() -> MedicineLogDataManager {
    let medicineStore = EntryListFileStore()
    return MedicineLogDataManager(
        persistenceManager: FilePersistenceManager(store: medicineStore)
    )
}

public func makeTestDrugSelectionListModel() -> DrugSelectionListModel {
    DrugSelectionListModel(
        selectableDrugs: [
            DrugSelectionListRowModel(
                drug: SelectableDrug(drugName: "Drug", drugId: "a"),
                count: 8,
                canTake: true,
                isSelected: false,
                didSelect: {}
            ),
            DrugSelectionListRowModel(
                drug: SelectableDrug(drugName: "Drug", drugId: "b"),
                count: 8,
                canTake: true,
                isSelected: false,
                didSelect: {}
            ),
            DrugSelectionListRowModel(
                drug: SelectableDrug(drugName: "Drug", drugId: "c"),
                count: 8,
                canTake: true,
                isSelected: true,
                didSelect: {}
            ),
            DrugSelectionListRowModel(
                drug: SelectableDrug(drugName: "Drug", drugId: "d"),
                count: 8,
                canTake: true,
                isSelected: false,
                didSelect: {}
            ),
            DrugSelectionListRowModel(
                drug: SelectableDrug(drugName: "Drug", drugId: "e"),
                count: 77,
                canTake: false,
                isSelected: false,
                didSelect: {}
            ),
            DrugSelectionListRowModel(
                drug: SelectableDrug(drugName: "Drug", drugId: "f"),
                count: 8,
                canTake: false,
                isSelected: true,
                didSelect: {}
            ),
            DrugSelectionListRowModel(
                drug: SelectableDrug(drugName: "Drug", drugId: "g"),
                count: 8,
                canTake: true,
                isSelected: false,
                didSelect: {}
            ),
            DrugSelectionListRowModel(
                drug: SelectableDrug(drugName: "Drug", drugId: "h"),
                count: 8,
                canTake: true,
                isSelected: false,
                didSelect: {}
            )
        ]
    )
}
