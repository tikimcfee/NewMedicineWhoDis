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
    private var current: Drug = Drug("", [], 4, id: "")
    lazy var binding = Binding<Drug>(
        get: { () -> Drug in self.current },
        set: { (val: Drug) in self.current = val }
    )
}

public final class TestData {

    public static let shared = TestData()

    @State static var inProgressEntry: InProgressEntry = InProgressEntry()

    static func drugMapBinding() -> Binding<[Drug : Int]> {
        return Binding<[Drug : Int]>(
            get: { () -> [Drug : Int] in [:] },
            set: { (_ : [Drug : Int]) in }
        )
    }

    static func drugBinding() -> Binding<Drug?> {
        return Binding<Drug?>(
            get: { () -> Drug? in Drug("", [], 4, id: "") },
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
            Array(drugs[start...end]).reduce(into: DrugCountMap()) { result, drug in
                result[drug, default: 0] += Double.random(in: 1...4)
            }
        )
    }

    lazy var randomEntries: [MedicineEntry] = {
        return [randomEntry(), randomEntry(), randomEntry(), randomEntry()]
    }()

    lazy var defaultEntry : MedicineEntry = {
        return MedicineEntry(
            Calendar.current.date(byAdding: .hour, value: -12, to: Date())!,
            Array(drugs[0...4]).reduce(into: DrugCountMap()) { result, drug in
                result[drug, default: 0] += Double.random(in: 1...4)
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
    return MedicineLogDataManager(supportedManager: .flatFile)
}

func randomNameString(length: Int = 7)->String{
    enum s {
        static let c = Array("abcdefghjklmnpqrstuvwxyz12345789")
        static let k = UInt32(c.count)
    }
    var result = [Character](repeating: "-", count: length)
    for i in 0..<length {
        let r = Int(arc4random_uniform(s.k))
        result[i] = s.c[r]
    }
    return String(result)
}

public func makeTestDrugSelectionListModel() -> DrugSelectionListModel {
    let models = (0..<10).map { _ in
        DrugSelectionListRowModel(
            drug: SelectableDrug(drugName: randomNameString(), drugId: randomNameString(), updateCount: { _ in }),
            count: Double.random(in: 0..<8),
            canTake: Bool.random(),
            timingMessage: "Next ready at 9:02 PM",
            timingIcon: Bool.random() ? "🕦" : "🕥",
            isSelected: Bool.random(),
            didSelect: { }
        )
    }
    return DrugSelectionListModel(
        selectableDrugs: models
    )
}
