//
//  MedicineDefinitions.swift
//  Drugs!
//
//  Created by Ivan Lugo on 9/7/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import Foundation

public struct Ingredient: Storable {
    let ingredientName: String
}

public struct Drug: Storable {
    let drugName: String
    let ingredients: [Ingredient]
    let hourlyDoseTime: Int
    
    static func blank() -> Drug {
        Drug(
			drugName: "<default drug binding\(UUID.init().uuidString)>",
            ingredients: [],
            hourlyDoseTime: 4
        )
    }
}

public struct MedicineEntry: Storable {
    let date: Date
    let drugsTaken: [Drug:Int]
    let randomId: String
    
    init(
        date: Date,
        drugsTaken: [Drug:Int],
        _ randomId: String = UUID.init().uuidString
    ) {
        self.date = date
        self.drugsTaken = drugsTaken
        self.randomId = randomId
    }
}

// ---------------------------------------------------
// ---------------------------------------------------
// ---------------------------------------------------


extension Drug {
    var ingredientList: String {
        if self.ingredients.count == 1 && self.ingredients.first?.ingredientName == self.drugName {
            return ""
        } else {
            return self.ingredients.map { $0.ingredientName }.joined(separator: ", ")
        }
    }
    
    var doseTimeInSeconds: Double {
        return Double(hourlyDoseTime) * 60.0 * 60.0
    }
}

extension MedicineEntry {
    var drugList: String {
        if self.drugsTaken.count == 0 {
            return "(Nothing taken)"
        } else {
            return self.drugsTaken.keys.map { $0.drugName }.joined(separator: ", ")
        }
    }
    
    var timesDrugsAreNextAvailable: [Drug: Date] {
        var result: [Drug: Date] = [:]
        drugsTaken
			.sorted { l, r in l.key.drugName.compare(r.key.drugName) == .orderedAscending }
			.forEach { pair in
            result[pair.key] = self.date.advanced(by: pair.key.doseTimeInSeconds)
        }
        return result
    }
}

// ---------------------------------------------------
// ---------------------------------------------------
// ---------------------------------------------------

public let __testData__listOfDrugs: [Drug] = {
    var drugs: [Drug] = [
        Drug(
            drugName: "Tylenol",
            ingredients: [
                Ingredient(ingredientName: "Acetaminophen")
            ],
            hourlyDoseTime: 6
        ),
        Drug(
            drugName: "Advil",
            ingredients: [
                Ingredient(ingredientName: "Naproxen Sodium")
            ],
            hourlyDoseTime: 6
        ),
        Drug(
            drugName: "Venlafaxine",
            ingredients: [
                Ingredient(ingredientName: "Venlafaxine")
            ],
            hourlyDoseTime: 6
        ),
        Drug(
            drugName: "Excedrin",
            ingredients: [
                Ingredient(ingredientName: "Acetaminophen"),
                Ingredient(ingredientName: "Aspirin"),
                Ingredient(ingredientName: "Caffeine")
            ],
            hourlyDoseTime: 6
        ),
        Drug(
            drugName: "Ibuprofen",
            ingredients: [
                Ingredient(ingredientName: "Ibuprofen")
            ],
            hourlyDoseTime: 6
        ),
        Drug(
            drugName: "Propranolol",
            ingredients: [
                Ingredient(ingredientName: "Propranolol")
            ],
            hourlyDoseTime: 12
        ),
        Drug(
            drugName: "Buspirone",
            ingredients: [
                Ingredient(ingredientName: "Buspirone")
            ]
            ,
            hourlyDoseTime: 24
        ),
        Drug(
            drugName: "Trazadone",
            ingredients: [
                Ingredient(ingredientName: "Trazadone")
            ],
            hourlyDoseTime: 24
        ),
        Drug(
            drugName: "Tums",
            ingredients: [
                Ingredient(ingredientName: "Sodium Bicarbonate")
            ],
            hourlyDoseTime: 4
        ),
        Drug(
            drugName: "Herb",
            ingredients: [
                Ingredient(ingredientName: "THC"),
                Ingredient(ingredientName: "CBD")
            ],
            hourlyDoseTime: 1
        ),
		Drug(
            drugName: "Diphenhydramine",
            ingredients: [
                Ingredient(ingredientName: "Diphenhydramine"),
            ],
            hourlyDoseTime: 1
        ),
		Drug(
            drugName: "Simethicone",
            ingredients: [
                Ingredient(ingredientName: "Simethicone"),
            ],
            hourlyDoseTime: 1
        ),
    ]
    return drugs
}()

public let __testData__anEntry: MedicineEntry = {
    return MedicineEntry(
			date: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
            drugsTaken: [
                Drug(
                    drugName: "Drugs",
                    ingredients: [Ingredient(ingredientName: "Sunshine")],
                    hourlyDoseTime: 1
                ) : 2,
                Drug(
                    drugName: "A great stuff",
                    ingredients: [Ingredient(ingredientName: "Milk")],
                    hourlyDoseTime: 2
                ) : 1,
                Drug(
                    drugName: "Allthepots",
                    ingredients: [Ingredient(ingredientName: "Sunshine")],
                    hourlyDoseTime: 3
                ) : 2,
                Drug(
                    drugName: "Pepto",
                    ingredients: [Ingredient(ingredientName: "Sunshine")],
                    hourlyDoseTime: 4
                ) : 1,
                Drug(
                    drugName: "Sugar",
                    ingredients: [Ingredient(ingredientName: "Sunshine")],
                    hourlyDoseTime: 24
                ) : 3,
			]
		)
}()

public let __testData__coreMedicineOperator: MedicineLogOperator = {
    let medicineStore = MedicineLogStore()
    let loadedState = medicineStore.load() ?? CoreAppState()
    
    return MedicineLogOperator(
        medicineStore: medicineStore,
        coreAppState: loadedState
    )
}()
