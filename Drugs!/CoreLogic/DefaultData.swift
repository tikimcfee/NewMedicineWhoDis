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
    private var current: Drug = Drug.blank()
    lazy var binding = Binding<Drug>(
        get: { () -> Drug in self.current },
        set: { (val: Drug) in self.current = val }
    )
}

public final class DefaultDrugList {

    @State static var inProgressEntry: InProgressEntry = InProgressEntry()

    static func drugMapBinding() -> Binding<[Drug : Int]> {
        return Binding<[Drug : Int]>(
            get: { () -> [Drug : Int] in [:] },
            set: { (_ : [Drug : Int]) in }
        )
    }

    static func drugBinding() -> Binding<Drug?> {
        return Binding<Drug?>(
            get: { () -> Drug? in Drug.blank() },
            set: { (Drug) in }
        )
    }

    public static let shared = DefaultDrugList()

    private init() { }

    lazy var defaultEntry : MedicineEntry = {
        return MedicineEntry(
            date: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
            drugsTaken: Array(drugs[0...4]).reduce(into: [Drug: Int]()) { result, drug in
                result[drug, default: 0] += Int.random(in: 1...4)
            }
        )
    }()

    lazy var drugs: [Drug] = {
        let list = [
            Drug(
                drugName: "Tylenol",
                ingredients: [
                    Ingredient("Acetaminophen")
                ],
                hourlyDoseTime: 5
            ),
            Drug(
                drugName: "Venlafaxine",
                ingredients: [
                    Ingredient("Venlafaxine")
                ],
                hourlyDoseTime: 24
            ),
            Drug(
                drugName: "Excedrin",
                ingredients: [
                    Ingredient("Acetaminophen"),
                    Ingredient("Aspirin"),
                    Ingredient("Caffeine")
                ],
                hourlyDoseTime: 5
            ),
            Drug(
                drugName: "Ibuprofen",
                ingredients: [
                    Ingredient("Ibuprofen")
                ],
                hourlyDoseTime: 8
            ),
            Drug(
                drugName: "Omeprazole",
                ingredients: [
                    Ingredient("Omeprazole")
                ],
                hourlyDoseTime: 24
            ),
            Drug(
                drugName: "Melatonin",
                ingredients: [
                    Ingredient("Melatonin")
                ],
                hourlyDoseTime: 24
            ),
            Drug(
                drugName: "Tums",
                ingredients: [
                    Ingredient("Sodium Bicarbonate")
                ],
                hourlyDoseTime: 4
            ),
            Drug(
                drugName: "Vitamins",
                ingredients: [
                    Ingredient("Vitamins")
                ],
                hourlyDoseTime: 0
            )
        ]

        return list.sorted { lhs, rhs in
            return lhs.drugName <= rhs.drugName
        }
    }()

}

public func makeTestMedicineOperator() -> MedicineLogOperator {
    let medicineStore = MedicineLogStore()
    var loaded: AppState? = nil
    medicineStore.load {
        switch $0 {
        case .success(let state):
            loaded = state
        case .failure:
            loaded = AppState()
        }
    }
    return MedicineLogOperator(
        medicineStore: medicineStore,
        coreAppState: loaded ?? AppState()
    )
}
