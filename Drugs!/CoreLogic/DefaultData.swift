//
//  MedicineDefinitions__TestData.swift
//  Drugs!
//
//  Created by Ivan Lugo on 12/5/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import Foundation

final class DefaultDrugList {
    lazy var defaultEntry : MedicineEntry = {
        return MedicineEntry(
            date: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
            drugsTaken: drugs.reduce(into: [Drug: Int]()) { result, drug in
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
                hourlyDoseTime: 6
            ),
            Drug(
                drugName: "Advil",
                ingredients: [
                    Ingredient("Naproxen Sodium")
                ],
                hourlyDoseTime: 6
            ),
            Drug(
                drugName: "Venlafaxine",
                ingredients: [
                    Ingredient("Venlafaxine")
                ],
                hourlyDoseTime: 6
            ),
            Drug(
                drugName: "Excedrin",
                ingredients: [
                    Ingredient("Acetaminophen"),
                    Ingredient("Aspirin"),
                    Ingredient("Caffeine")
                ],
                hourlyDoseTime: 6
            ),
            Drug(
                drugName: "Ibuprofen",
                ingredients: [
                    Ingredient("Ibuprofen")
                ],
                hourlyDoseTime: 6
            ),
            Drug(
                drugName: "Propranolol",
                ingredients: [
                    Ingredient("Propranolol")
                ],
                hourlyDoseTime: 12
            ),
            Drug(
                drugName: "Buspirone",
                ingredients: [
                    Ingredient("Buspirone")
                ]
                ,
                hourlyDoseTime: 24
            ),
            Drug(
                drugName: "Trazadone",
                ingredients: [
                    Ingredient("Trazadone")
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
                drugName: "Herb",
                ingredients: [
                    Ingredient("THC"),
                    Ingredient("CBD")
                ],
                hourlyDoseTime: 1
            ),
            Drug(
                drugName: "Diphenhydramine",
                ingredients: [
                    Ingredient("Diphenhydramine"),
                ],
                hourlyDoseTime: 1
            ),
            Drug(
                drugName: "Simethicone",
                ingredients: [
                    Ingredient("Simethicone"),
                ],
                hourlyDoseTime: 1
            )
        ]

        return list.sorted { lhs, rhs in
            return lhs.drugName <= rhs.drugName
        }
    }()

}

public func makeTestMedicineOperator() -> MedicineLogOperator {
    let medicineStore = MedicineLogStore()
    let loadedState = medicineStore.load()
    return MedicineLogOperator(
        medicineStore: medicineStore,
        coreAppState: loadedState
    )
}
