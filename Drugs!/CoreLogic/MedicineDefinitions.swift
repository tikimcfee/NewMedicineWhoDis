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
    
    static func blank() -> Drug {
        Drug(drugName: "", ingredients: [])
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
}

extension MedicineEntry {
    var drugList: String {
        if self.drugsTaken.count == 0 {
            return "(Nothing taken)"
        } else {
            return self.drugsTaken.keys.map { $0.drugName }.joined(separator: ", ")
        }
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
            ]
        ),
        Drug(
            drugName: "Advil",
            ingredients: [
                Ingredient(ingredientName: "Naproxen Sodium")
            ]
        ),
        Drug(
            drugName: "Venlafaxine",
            ingredients: [
                Ingredient(ingredientName: "Venlafaxine")
            ]
        ),
        Drug(
            drugName: "Excedrin",
            ingredients: [
                Ingredient(ingredientName: "Acetaminophen"),
                Ingredient(ingredientName: "Aspirin"),
                Ingredient(ingredientName: "Caffeine")
            ]
        ),
        Drug(
            drugName: "Ibuprofen",
            ingredients: [
                Ingredient(ingredientName: "Ibuprofen")
            ]
        ),
        Drug(
            drugName: "Propranolol",
            ingredients: [
                Ingredient(ingredientName: "Propranolol")
            ]
        ),
        Drug(
            drugName: "Buspirone",
            ingredients: [
                Ingredient(ingredientName: "Buspirone")
            ]
        ),
        Drug(
            drugName: "Trazadone",
            ingredients: [
                Ingredient(ingredientName: "Trazadone")
            ]
        ),
        Drug(
            drugName: "Tums",
            ingredients: [
                Ingredient(ingredientName: "Sodium Bicarbonate")
            ]
        ),
        Drug(
            drugName: "Funky Green Shit",
            ingredients: [
                Ingredient(ingredientName: "THC"),
                Ingredient(ingredientName: "CBD")
            ]
        ),
    ]
    return drugs
}()

public let __testData__coreMedicineOperator: MedicineLogOperator = {
    let medicineStore = MedicineLogStore()
    let loadedState = medicineStore.load() ?? CoreAppState()
    
    return MedicineLogOperator(
        medicineStore: medicineStore,
        coreAppState: loadedState
    )
}()
